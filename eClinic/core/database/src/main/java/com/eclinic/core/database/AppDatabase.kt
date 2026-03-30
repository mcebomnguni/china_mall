package com.eclinic.core.database

import androidx.room.Database
import androidx.room.RoomDatabase
import com.eclinic.core.database.dao.ConsultationDao
import com.eclinic.core.database.dao.PatientDao
import com.eclinic.core.database.dao.VitalsDao
import com.eclinic.core.database.entity.ConsultationEntity
import com.eclinic.core.database.entity.PatientEntity
import com.eclinic.core.database.entity.VitalsEntity

@Database(
    entities = [
        PatientEntity::class,
        ConsultationEntity::class,
        VitalsEntity::class
    ],
    version = 1,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun patientDao(): PatientDao
    abstract fun consultationDao(): ConsultationDao
    abstract fun vitalsDao(): VitalsDao
}
