package com.khandoba.securedocs.ui.media

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.camera.video.FileOutputOptions
import androidx.camera.video.MediaStoreOutputOptions
import androidx.camera.video.Quality
import androidx.camera.video.QualitySelector
import androidx.camera.video.Recorder
import androidx.camera.video.Recording
import androidx.camera.video.VideoCapture
import androidx.camera.video.VideoRecordEvent
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import kotlinx.coroutines.delay
import java.io.File
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

@Composable
fun VideoRecordingView(
    onVideoRecorded: (android.net.Uri) -> Unit,
    onDismiss: () -> Unit
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val cameraExecutor: ExecutorService = remember { Executors.newSingleThreadExecutor() }
    
    var isRecording by remember { mutableStateOf(false) }
    var recordingTime by remember { mutableStateOf(0) }
    var videoUri by remember { mutableStateOf<android.net.Uri?>(null) }
    var videoCapture: VideoCapture<Recorder>? by remember { mutableStateOf(null) }
    var recording: Recording? by remember { mutableStateOf(null) }
    
    // Recording time timer
    LaunchedEffect(isRecording) {
        if (isRecording) {
            while (isRecording) {
                delay(1000)
                recordingTime++
            }
        } else {
            recordingTime = 0
        }
    }
    
    DisposableEffect(Unit) {
        onDispose {
            recording?.stop()
            cameraExecutor.shutdown()
        }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Record Video") },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, contentDescription = "Close")
                    }
                }
            )
        }
    ) { padding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            // Camera Preview
            AndroidView(
                factory = { ctx ->
                    val previewView = PreviewView(ctx)
                    val cameraProviderFuture = ProcessCameraProvider.getInstance(ctx)
                    
                    cameraProviderFuture.addListener({
                        val cameraProvider = cameraProviderFuture.get()
                        
                        val preview = Preview.Builder().build().also {
                            it.setSurfaceProvider(previewView.surfaceProvider)
                        }
                        
                        // Video recording setup
                        val recorder = Recorder.Builder()
                            .setQualitySelector(QualitySelector.from(Quality.HIGHEST))
                            .build()
                        val videoCaptureUseCase = VideoCapture.withOutput(recorder)
                        videoCapture = videoCaptureUseCase
                        
                        val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA
                        
                        try {
                            cameraProvider.unbindAll()
                            cameraProvider.bindToLifecycle(
                                lifecycleOwner,
                                cameraSelector,
                                preview,
                                videoCaptureUseCase
                            )
                        } catch (e: Exception) {
                            android.util.Log.e("VideoRecordingView", "Camera setup failed: ${e.message}")
                        }
                    }, ContextCompat.getMainExecutor(ctx))
                    
                    previewView
                },
                modifier = Modifier.fillMaxSize()
            )
            
            // Recording controls
            Column(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(32.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Recording indicator
                if (isRecording) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Icon(
                            Icons.Default.FiberManualRecord,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.error
                        )
                        Text("Recording: ${formatTime(recordingTime)}")
                    }
                }
                
                // Record button
                FloatingActionButton(
                    onClick = {
                        if (isRecording) {
                            // Stop recording
                            recording?.stop()
                            recording = null
                            isRecording = false
                            
                            // Call callback with recorded video URI
                            videoUri?.let { uri ->
                                onVideoRecorded(uri)
                            }
                        } else {
                            // Start recording
                            val videoCapture = videoCapture ?: return@FloatingActionButton
                            
                            // Create output file
                            val videoFile = File(
                                context.getExternalFilesDir(Environment.DIRECTORY_MOVIES),
                                "VID_${SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())}.mp4"
                            )
                            
                            val mediaStoreOutputOptions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                val contentValues = ContentValues().apply {
                                    put(MediaStore.Video.Media.RELATIVE_PATH, "Movies/KhandobaSecureDocs")
                                    put(MediaStore.Video.Media.MIME_TYPE, "video/mp4")
                                }
                                MediaStoreOutputOptions.Builder(
                                    context.contentResolver,
                                    MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                                )
                                    .setContentValues(contentValues)
                                    .build()
                            } else {
                                val fileUri = FileProvider.getUriForFile(
                                    context,
                                    "${context.packageName}.fileprovider",
                                    videoFile
                                )
                                FileOutputOptions.Builder(videoFile).build()
                            }
                            
                            recording = videoCapture.output
                                .prepareRecording(context, mediaStoreOutputOptions)
                                .withAudioEnabled()
                                .start(cameraExecutor) { event ->
                                    when (event) {
                                        is VideoRecordEvent.Start -> {
                                            isRecording = true
                                            videoUri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                                mediaStoreOutputOptions.outputUriOptions.uri
                                            } else {
                                                FileProvider.getUriForFile(
                                                    context,
                                                    "${context.packageName}.fileprovider",
                                                    videoFile
                                                )
                                            }
                                        }
                                        is VideoRecordEvent.Finalize -> {
                                            if (!event.hasError()) {
                                                android.util.Log.d("VideoRecordingView", "Video recorded successfully: ${videoUri}")
                                            } else {
                                                android.util.Log.e("VideoRecordingView", "Video recording error: ${event.cause}")
                                            }
                                        }
                                        else -> {}
                                    }
                                }
                        }
                    },
                    containerColor = if (isRecording) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.primary
                ) {
                    Icon(
                        if (isRecording) Icons.Default.Stop else Icons.Default.Videocam,
                        contentDescription = if (isRecording) "Stop" else "Record"
                    )
                }
            }
        }
    }
}

private fun formatTime(seconds: Int): String {
    val minutes = seconds / 60
    val secs = seconds % 60
    return String.format("%02d:%02d", minutes, secs)
}
