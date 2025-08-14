package com.sscheffler.campuscommotion

import org.junit.Test
import org.junit.Assert.*

/**
 * Basic unit test to validate project structure and compilation
 */
class BasicUnitTest {
    @Test
    fun addition_isCorrect() {
        assertEquals(4, 2 + 2)
    }
    
    @Test
    fun blockStyling_appliesCorrectColors() {
        val color = com.sscheffler.campuscommotion.util.BlockStyling.applyStyling("A")
        assertEquals("#f25c5a", color)
    }
    
    @Test
    fun scheduleModels_canBeCreated() {
        val block = com.sscheffler.campuscommotion.data.model.ScheduleBlock(
            date = "Monday 12/4",
            blockid = "A",
            color = "#f25c5a",
            starttime = "8:00",
            pmstart = false,
            endtime = "8:50",
            pmend = false,
            classname = "Math",
            location = "Room 101"
        )
        
        assertEquals("A", block.blockid)
        assertEquals("Math", block.classname)
    }
}