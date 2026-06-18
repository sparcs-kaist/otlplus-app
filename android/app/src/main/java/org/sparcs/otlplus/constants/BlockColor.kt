package org.sparcs.otlplus.constants

import org.sparcs.otlplus.R
import org.sparcs.otlplus.api.Lecture

object BlockColor {
    val blockColorsLayout = arrayOf(
        R.layout.timetable_block0,
        R.layout.timetable_block1,
        R.layout.timetable_block2,
        R.layout.timetable_block3,
        R.layout.timetable_block4,
        R.layout.timetable_block5,
        R.layout.timetable_block6,
        R.layout.timetable_block7,
        R.layout.timetable_block8,
        R.layout.timetable_block9,
        R.layout.timetable_block10,
        R.layout.timetable_block11,
        R.layout.timetable_block12,
        R.layout.timetable_block13,
        R.layout.timetable_block14,
        R.layout.timetable_block15,
    )

    val blockColors = intArrayOf(
        0xFFF2CECE.toInt(),
        0xFFF4B3AE.toInt(),
        0xFFF2BCA0.toInt(),
        0xFFF0D3AB.toInt(),
        0xFFF1E1A9.toInt(),
        0xFFF4F2B3.toInt(),
        0xFFDBF4BE.toInt(),
        0xFFBEEDD7.toInt(),
        0xFFB7E2DE.toInt(),
        0xFFC9EAF4.toInt(),
        0xFFB4D3ED.toInt(),
        0xFFB9C5ED.toInt(),
        0xFFCCC6ED.toInt(),
        0xFFD8C1F0.toInt(),
        0xFFEBCAEF.toInt(),
        0xFFF4BADB.toInt(),
    )

    fun getLayout(lecture: Lecture) = blockColorsLayout[lecture.course % 16]

    fun getColor(course: Int) = blockColors[course % 16]
}