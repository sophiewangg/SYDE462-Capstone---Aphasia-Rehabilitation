import os
import numpy as np
import librosa
import scipy.stats
import warnings
import noisereduce as nr
from scipy.signal import butter, sosfilt
import xgboost as xgb
import io
import soundfile as sf
import pickle
import uuid
from datetime import datetime
from pydub import AudioSegment
import shutil

class DisfluencyDetectionService:
    def __init__(self):
        self.model_sound_rep = None
        self.scaler_sound_rep = None
        self.le_sound_rep = None

        self.model_interjection = None
        self.scaler_interjection = None
        self.le_interjection = None

        # Setup paths relative to this file
        self.current_dir = os.path.dirname(os.path.abspath(__file__))
        self.project_root = os.path.dirname(self.current_dir)
        self.model_dir = os.path.join(self.project_root, "classification_models")

        # At the top of your service or in your __init__
        self.detections_dir = os.path.join(self.project_root, "detections")
        os.makedirs(self.detections_dir, exist_ok=True)

    def detect_disfluencies(self, raw_filename):
        from worker import process_recording_pipeline
        
        # Path to the detections folder
        detections_dir = './detections'
    
        # Delete everything inside the folder
        if os.path.exists(detections_dir):
            for filename in os.listdir(detections_dir):
                file_path = os.path.join(detections_dir, filename)
                try:
                    if os.path.isfile(file_path) or os.path.islink(file_path):
                        os.unlink(file_path) # Delete files and symlinks
                    elif os.path.isdir(file_path):
                        shutil.rmtree(file_path) # Delete subdirectories
                except Exception as e:
                    print(f'Failed to delete {file_path}. Reason: {e}')
        process_recording_pipeline.delay(raw_filename)
        
    def _load_assets(self):
        """Loads model, scaler, and encoder if they aren't already in memory."""
        if self.model_sound_rep is None:
            # Load Sound Rep model, scaler, label encoder
            self.model_sound_rep = xgb.XGBClassifier()
            self.model_sound_rep.load_model(os.path.join(self.model_dir, "sound_rep_xgb_model.json"))

            with open(os.path.join(self.model_dir, "scaler_sound_rep.pkl"), "rb") as f:
                self.scaler_sound_rep = pickle.load(f)

            with open(os.path.join(self.model_dir, "label_encoder_sound_rep.pkl"), "rb") as f:
                self.le_sound_rep = pickle.load(f)

        if self.model_interjection is None:
            # Load Interjection model scaler, label encode
            self.model_interjection = xgb.XGBClassifier()
            self.model_interjection.load_model(os.path.join(self.model_dir, "interjection_xgb_model.json"))

            with open(os.path.join(self.model_dir, "scaler_interjection.pkl"), "rb") as f:
                self.scaler_interjection = pickle.load(f)

            with open(os.path.join(self.model_dir, "label_encoder_interjection.pkl"), "rb") as f:
                self.le_interjection = pickle.load(f)

    def butterfly_bandpass(self, y, sr, lowcut=75, highcut=8000, order=5):
        nyq = 0.5 * sr
        if highcut >= nyq:
            highcut = nyq - 1.0     
        low = lowcut / nyq
        high = highcut / nyq
        sos = butter(order, [low, high], btype='band', output='sos')
        return sosfilt(sos, y)
    
    def preprocess_audio(self, audio_bytes, sr, duration, pretreatment):
        # 1. Convert bytes to a file-like object
        # If you're already passing a BytesIO object, this ensures we're at the start
        if isinstance(audio_bytes, bytes):
            buffer = io.BytesIO(audio_bytes)
        else:
            buffer = audio_bytes
            buffer.seek(0)

        # 2. Load the audio data using soundfile
        # This bypasses the librosa "stat" error for in-memory objects
        y, native_sr = sf.read(buffer)

        # 3. Standardize format: soundfile is (samples, channels), librosa expects (channels, samples)
        if len(y.shape) > 1:
            y = np.mean(y, axis=1) # Convert to mono if needed

        # 4. Resample if the source doesn't match your target 16kHz
        if native_sr != sr:
            y = librosa.resample(y, orig_sr=native_sr, target_sr=sr)

        if len(y) == 0:
            return None
        # 2. OPTIMIZATION: Trim Silence FIRST to reduce data size
        # We normalize slightly before trim to ensure thresholding works consistently
        y = y / (np.max(np.abs(y)) + 1e-9)
        y, _ = librosa.effects.trim(y, top_db=25)

        # 3. OPTIMIZATION: Crop to duration FIRST
        # If the file is 10 minutes long, we only care about the first 3 seconds anyway.
        # Don't waste RAM processing the rest.
        target_len = int(sr * duration)
        if len(y) > target_len:
            y = y[:target_len] # Crop immediately

        # 4. NOW Apply Filters (On the much smaller array)
        y = self.butterfly_bandpass(y, sr=sr)

        # 5. NOW Apply Noise Reduce (On the small array)
        # This is now safe because 'y' is guaranteed to be small (max 3 seconds)
        if pretreatment in ['noisereduce', 'pcen_and_noisereduce']:
            # We use a stationary noise reduction since the clip is short
            try:
                y = nr.reduce_noise(y=y, sr=sr, stationary=True)
            except:
                pass # If clip is too short for NR, skip it

        # 6. Pad if necessary (if it was shorter than target_len)
        if len(y) < target_len:
            y = np.pad(y, (0, target_len - len(y)))

        return y
    
    def extract_features_sound_rep(self, audio_bytes, sr=16000, duration=3.0, pretreatment='noisereduce'):
        warnings.filterwarnings("ignore")
        try:
            y = self.preprocess_audio(audio_bytes, sr, duration, pretreatment)

            # --- Feature Extraction (Same as before) ---
            mfcc = librosa.feature.mfcc(y=y, sr=sr, n_mfcc=13)
            delta = librosa.feature.delta(mfcc)
            delta2 = librosa.feature.delta(mfcc, order=2)
            mfcc_all = np.vstack([mfcc, delta, delta2])
            mfcc_mean = np.mean(mfcc_all, axis=1)
            mfcc_std  = np.std(mfcc_all, axis=1)

            mel = librosa.feature.melspectrogram(y=y, sr=sr, n_mels=64, fmin=20, fmax=8000)

            if pretreatment in ['pcen', 'pcen_and_noisereduce']:
                logmel = librosa.pcen(mel * (2**31), sr=sr, time_constant=0.400, gain=0.98, bias=2, power=0.5)
            else:
                logmel = librosa.power_to_db(mel)

            mel_mean = np.mean(logmel, axis=1)
            mel_std  = np.std(logmel, axis=1)

            mel_mean = (mel_mean - mel_mean.mean()) / (mel_mean.std() + 1e-6)
            mel_std  = (mel_std  - mel_std.mean())  / (mel_std.std() + 1e-6)

            rms = librosa.feature.rms(y=y)[0]
            rms_mean = float(np.mean(rms))
            rms_std  = float(np.std(rms))

            # Re-calc silence ratio on the specific trimmed/processed clip
            # (Note: Since we trimmed at the start, this ratio will likely be low, which is fine)
            nonsilent = librosa.effects.split(y, top_db=25)
            total_ns = np.sum([(e - s) for s, e in nonsilent]) if len(nonsilent) else 0
            pause_ratio = 1 - (total_ns / len(y))

            onset_env = librosa.onset.onset_strength(y=y, sr=sr)
            onset_frames = librosa.onset.onset_detect(onset_envelope=onset_env, sr=sr, backtrack=False)
            onset_rate = len(onset_frames) / duration 
            if len(onset_frames) > 0:
                mean_onset_strength = float(np.mean(onset_env[onset_frames]))
                std_onset_strength  = float(np.std(onset_env[onset_frames]))
            else:
                mean_onset_strength = 0.0
                std_onset_strength  = 0.0

            spectral_flux = np.sqrt(np.sum(np.diff(logmel, axis=1)**2, axis=0))
            flux_mean = float(np.mean(spectral_flux))
            flux_std  = float(np.std(spectral_flux))

            zcr = librosa.feature.zero_crossing_rate(y)[0]
            zcr_mean = float(np.mean(zcr))
            zcr_std  = float(np.std(zcr))

            features = np.concatenate([
                mfcc_mean, mfcc_std,
                mel_mean, mel_std,
                [rms_mean, rms_std],
                [pause_ratio],
                [onset_rate, mean_onset_strength, std_onset_strength],
                [flux_mean, flux_std, zcr_mean, zcr_std]
            ])

            return features.astype(np.float32)

        except Exception as e:
            print(f"Error processing: {e}")
            return None
        
    def classify_sound_rep(self, audio_buffer, threshold=0.80):
        # 1. Extract raw features using your existing logic
        feats = self.extract_features_sound_rep(audio_buffer)
        if feats is None:
            return None, 0.0

        # 2. Ensure assets are loaded
        self._load_assets()

        # 3. Scale the features (Crucial step from your predict.py!)
        X = feats.reshape(1, -1)
        X_scaled = self.scaler_sound_rep.transform(X)

        # 4. Get Probabilities and Predictions
        proba = self.model_sound_rep.predict_proba(X_scaled)[0]
        pred_idx = self.model_sound_rep.predict(X_scaled)[0]
        label = self.le_sound_rep.inverse_transform([pred_idx])[0]
        confidence = float(np.max(proba))

        # 5. Apply your specific logic: SoundRep + Threshold
        if label == "SoundRep" and confidence >= threshold:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            unique_id = str(uuid.uuid4())[:8]
            filename = f"{timestamp}_soundrep_{unique_id}.wav"
            save_path = os.path.join(self.detections_dir, filename)

            try:
                # Wrap bytes in BytesIO so pydub can 'read' it
                # We do this regardless of whether it's already a buffer or bytes
                audio_data = io.BytesIO(audio_buffer) if isinstance(audio_buffer, bytes) else audio_buffer
                audio_data.seek(0)
                
                audio_segment = AudioSegment.from_file(audio_data, format="wav")
                audio_segment.export(save_path, format="wav")
                
                print(f"✅ Detection saved: {filename} (Confidence: {confidence:.2f})")
            except Exception as e:
                print(f"❌ Failed to save detection clip: {e}")

            return label, confidence
        
        print(f"⚠️ Ignored: {label} (Conf: {confidence:.2f})")
        return "Not SoundRep", confidence
    
    def extract_features_interjection(self, audio_bytes, sr=16000, duration=3.0, pretreatment='noisereduce'):
        warnings.filterwarnings("ignore")
        try:
            y = self.preprocess_audio(audio_bytes, sr, duration, pretreatment)

            mid = len(y) // 2
            y1 = y[:mid]
            y2 = y[mid:]

            # ===== MFCCs =====
            def mfcc_stats(signal):
                if len(signal) < 50:
                    return (np.zeros(39), np.zeros(39))
                mf = librosa.feature.mfcc(y=signal, sr=sr, n_mfcc=13)
                d1 = librosa.feature.delta(mf)
                d2 = librosa.feature.delta(mf, order=2)
                mf_all = np.vstack([mf, d1, d2])
                return np.mean(mf_all, axis=1), np.std(mf_all, axis=1)

            mfcc1_mean, mfcc1_std = mfcc_stats(y1)
            mfcc2_mean, mfcc2_std = mfcc_stats(y2)

            # ===== Log-Mel =====
            def mel_stats(signal):
                if len(signal) < 50:
                    return (np.zeros(64), np.zeros(64))
                mel = librosa.feature.melspectrogram(
                    y=signal, sr=sr, n_mels=64, fmin=20, fmax=8000
                )
                logmel = librosa.power_to_db(mel)
                return np.mean(logmel, axis=1), np.std(logmel, axis=1)

            mel1_mean, mel1_std = mel_stats(y1)
            mel2_mean, mel2_std = mel_stats(y2)

            # ===== RMS =====
            rms = librosa.feature.rms(y=y)[0]
            rms_mean = float(np.mean(rms))
            rms_std  = float(np.std(rms))

            # ===== ZCR =====
            zcr = librosa.feature.zero_crossing_rate(y)[0]
            zcr_mean = float(np.mean(zcr))
            zcr_std  = float(np.std(zcr))

            # ===== Spectral centroid & bandwidth =====
            centroid = librosa.feature.spectral_centroid(y=y, sr=sr)[0]
            bandwidth = librosa.feature.spectral_bandwidth(y=y, sr=sr)[0]
            centroid_mean = float(np.mean(centroid))
            bandwidth_mean = float(np.mean(bandwidth))

            # ===== Voicing =====
            # Pitch (may fail on silence)
            try:
                pitch = librosa.yin(y, fmin=80, fmax=300)
                pitch_mean = float(np.mean(pitch))
                pitch_std  = float(np.std(pitch))
            except:
                pitch_mean, pitch_std = 0.0, 0.0

            # Harmonic-percussive ratio
            try:
                harmonic, percussive = librosa.effects.hpss(y)
                hps_ratio = float(np.mean(harmonic) / (np.mean(percussive) + 1e-9))
            except:
                hps_ratio = 0.0

            # ===== Pause ratio =====
            nonsilent = librosa.effects.split(y, top_db=25)
            total_ns = np.sum([(e - s) for s, e in nonsilent]) if len(nonsilent) else 0
            pause_ratio = 1 - (total_ns / len(y))

            # --------------------------
            # Final Feature Vector
            # --------------------------
            features = np.concatenate([
                mfcc1_mean, mfcc1_std,
                mfcc2_mean, mfcc2_std,
                mel1_mean,  mel1_std,
                mel2_mean,  mel2_std,
                [rms_mean, rms_std],
                [centroid_mean, bandwidth_mean],
                [zcr_mean, zcr_std],
                [pitch_mean, pitch_std, hps_ratio],
                [pause_ratio]
            ])

            return features.astype(np.float32)

        except Exception as e:
            print(f"Error processing: {e}")
            return None

    def classify_interjection(self, audio_buffer, threshold=0.80):
        # 1. Extract raw features using your existing logic
        feats = self.extract_features_interjection(audio_buffer)
        if feats is None:
            return None, 0.0

        # 2. Ensure assets are loaded
        self._load_assets()

        # 3. Scale the features (Crucial step from your predict.py!)
        X = feats.reshape(1, -1)
        X_scaled = self.scaler_interjection.transform(X)

        # 4. Get Probabilities and Predictions
        proba = self.model_interjection.predict_proba(X_scaled)[0]
        pred_idx = self.model_interjection.predict(X_scaled)[0]
        label = self.le_interjection.inverse_transform([pred_idx])[0]
        confidence = float(np.max(proba))

        # 5. Apply your specific logic: SoundRep + Threshold
        if label == "Interjection" and confidence >= threshold:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            unique_id = str(uuid.uuid4())[:8]
            filename = f"{timestamp}_interjection_{unique_id}.wav"
            save_path = os.path.join(self.detections_dir, filename)

            try:
                # Wrap bytes in BytesIO so pydub can 'read' it
                # We do this regardless of whether it's already a buffer or bytes
                audio_data = io.BytesIO(audio_buffer) if isinstance(audio_buffer, bytes) else audio_buffer
                audio_data.seek(0)
                
                audio_segment = AudioSegment.from_file(audio_data, format="wav")
                audio_segment.export(save_path, format="wav")
                
                print(f"✅ Detection saved: {filename} (Confidence: {confidence:.2f})")
            except Exception as e:
                print(f"❌ Failed to save detection clip: {e}")

            return label, confidence
        
        print(f"⚠️ Ignored: {label} (Conf: {confidence:.2f})")
        return "Not Interjection", confidence