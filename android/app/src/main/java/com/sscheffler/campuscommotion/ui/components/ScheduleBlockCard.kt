package com.sscheffler.campuscommotion.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sscheffler.campuscommotion.data.model.ScheduleBlock
import com.sscheffler.campuscommotion.util.BlockStyling

@Composable
fun ScheduleBlockCard(
    block: ScheduleBlock,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Block color indicator
            Box(
                modifier = Modifier
                    .width(4.dp)
                    .height(48.dp)
                    .clip(RoundedCornerShape(2.dp))
                    .background(BlockStyling.getBlockColor(block.blockid))
            )
            
            Spacer(modifier = Modifier.width(12.dp))
            
            // Block content
            Column(
                modifier = Modifier.weight(1f)
            ) {
                // Block ID and time
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = block.blockid,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    
                    Text(
                        text = formatTime(block.starttime, block.pmstart, block.endtime, block.pmend),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                
                Spacer(modifier = Modifier.height(4.dp))
                
                // Class name
                if (block.classname.isNotEmpty()) {
                    Text(
                        text = block.classname,
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Medium
                    )
                }
                
                // Location
                if (block.location.isNotEmpty()) {
                    Text(
                        text = block.location,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}

private fun formatTime(startTime: String, pmStart: Boolean, endTime: String, pmEnd: Boolean): String {
    if (startTime == "All Day") return "All Day"
    
    val startSuffix = if (pmStart) "PM" else "AM"
    val endSuffix = if (pmEnd) "PM" else "AM"
    
    return "$startTime $startSuffix - $endTime $endSuffix"
}