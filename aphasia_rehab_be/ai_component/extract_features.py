
import os
import numpy as np
import librosa
import scipy.stats
import warnings
import noisereduce as nr
from scipy.signal import butter, sosfilt

warnings.filterwarnings("ignore")

def butterfly_bandpass(y, sr, lowcut=75, highcut=8000, order=5):
    nyq = 0.5 * sr
    if highcut >= nyq:
        highcut = nyq - 1.0     
    low = lowcut / nyq
    high = highcut / nyq
    sos = butter(order, [low, high], btype='band', output='sos')
    return sosfilt(sos, y)

def extract_features(filepath, sr=16000, duration=3.0, pretreatment='noisereduce'):
    try:
        if not os.path.exists(filepath):
            return None

        # 1. Load file
        y, sr = librosa.load(filepath, sr=sr)
        
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
        y = butterfly_bandpass(y, sr=sr)

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
        print(f"Error processing {filepath}: {e}")
        return None
