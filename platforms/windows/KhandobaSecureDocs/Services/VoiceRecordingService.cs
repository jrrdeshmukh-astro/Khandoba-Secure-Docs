using System;
using System.Threading.Tasks;
using Windows.Media.Capture;
using Windows.Media.MediaProperties;
using Windows.Storage;

namespace KhandobaSecureDocs.Services
{
    public class VoiceRecordingService
    {
        private MediaCapture? _mediaCapture;
        private LowLagMediaRecording? _lowLagRecording;
        private StorageFile? _currentRecordingFile;

        public bool IsRecording { get; private set; }

        public async Task InitializeAsync()
        {
            try
            {
                _mediaCapture = new MediaCapture();

                var settings = new MediaCaptureInitializationSettings
                {
                    StreamingCaptureMode = StreamingCaptureMode.Audio,
                    AudioDeviceId = string.Empty // Use default microphone
                };

                await _mediaCapture.InitializeAsync(settings);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Failed to initialize microphone: {ex.Message}");
                throw;
            }
        }

        public async Task StartRecordingAsync(StorageFile file)
        {
            if (_mediaCapture == null)
            {
                await InitializeAsync();
            }

            if (_mediaCapture == null)
            {
                throw new InvalidOperationException("Microphone not initialized");
            }

            try
            {
                var encodingProfile = MediaEncodingProfile.CreateM4a(AudioEncodingQuality.High);
                _lowLagRecording = await _mediaCapture.PrepareLowLagRecordToStorageFileAsync(
                    encodingProfile, file);

                await _lowLagRecording.StartAsync();
                _currentRecordingFile = file;
                IsRecording = true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Failed to start recording: {ex.Message}");
                throw;
            }
        }

        public async Task<StorageFile> StopRecordingAsync()
        {
            if (_lowLagRecording == null)
            {
                throw new InvalidOperationException("No active recording");
            }

            try
            {
                await _lowLagRecording.StopAsync();
                await _lowLagRecording.FinishAsync();
                IsRecording = false;

                var file = _currentRecordingFile;
                _currentRecordingFile = null;
                _lowLagRecording = null;

                return file!;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Failed to stop recording: {ex.Message}");
                throw;
            }
        }

        public void Dispose()
        {
            _mediaCapture?.Dispose();
            _lowLagRecording?.Dispose();
        }
    }
}
