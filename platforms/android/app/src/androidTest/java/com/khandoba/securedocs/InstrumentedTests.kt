package com.khandoba.securedocs

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Instrumented tests that run on Android device/emulator
 */
@RunWith(AndroidJUnit4::class)
class InstrumentedTests {
    @Test
    fun useAppContext() {
        // Context of the app under test
        val appContext = InstrumentationRegistry.getInstrumentation().targetContext
        assertEquals("com.khandoba.securedocs", appContext.packageName)
    }
}
