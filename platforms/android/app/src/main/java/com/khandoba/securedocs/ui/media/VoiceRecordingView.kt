package com.khandoba.securedocs.ui.media

import android.media.MediaRecorder
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import java.io.File

@Composable
fun VoiceRecordingView(
    onRecordingComplete: (File) -> Unit,
    onDismiss: () -> Unit
) {
    var isRecording by remember { mutableStateOf(false) }
    var recordingTime by remember { mutableStateOf(0) }
    var recorder by remember { mutableStateOf<MediaRecorder?>(null) }
    var outputFile by remember { mutableStateOf<File?>(null) }
    
    LaunchedEffect(isRecording) {
        if (isRecording) {
            // Start recording timer
            while (isRecording) {
                kotlinx.coroutines.delay(1000)
                recordingTime++
            }
        } else {
            recordingTime = 0
        }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Record Voice") },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, contentDescription = "Close")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            // Recording indicator
            if (isRecording) {
                Icon(
                    Icons.Default.Mic,
                    contentDescription = null,
                    modifier = Modifier.size(80.dp),
                    tint = MaterialTheme.colorScheme.error
                )
                
                Spacer(modifier = Modifier.height(24.dp))
                
                Text(
                    text = formatTime(recordingTime),
                    style = MaterialTheme.typography.headlineLarge
                )
            } else {
                Icon(
                    Icons.Default.Mic,
                    contentDescription = null,
                    modifier = Modifier.size(80.dp)
                )
            }
            
            Spacer(modifier = Modifier.height(48.dp))
            
            // Record button
            FloatingActionButton(
                onClick = {
                    if (isRecording) {
                        // Stop recording
                        recorder?.stop()
                        recorder?.release()
                        recorder = null
                        outputFile?.let { onRecordingComplete(it) }
                        isRecording = false
                    } else {
                        // Start recording
                        val file = File.createTempFile("recording", ".m4a")
                        outputFile = file
                        
                        recorder = MediaRecorder().apply {
                            setAudioSource(MediaRecorder.AudioSource.MIC)
                            setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                            setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                            setOutputFile(file.absolutePath)
                            prepare()
                            start()
                        }
                        
                        isRecording = true
                    }
                },
                modifier = Modifier.size(72.dp),
                containerColor = if (isRecording) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.primary
            ) {
                Icon(
                    if (isRecording) Icons.Default.Stop else Icons.Default.Mic,
                    contentDescription = if (isRecording) "Stop" else "Record",
                    modifier = Modifier.size(32.dp)
                )
            }
        }
    }
}

private fun formatTime(seconds: Int): String {
    val minutes = seconds / 60
    val secs = seconds % 60
    return String.format("%02d:%02d", minutes, secs)
}
