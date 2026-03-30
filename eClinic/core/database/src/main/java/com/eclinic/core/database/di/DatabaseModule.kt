package com.eclinic.core.database.di

import android.content.Context
import androidx.room.Room
import com.eclinic.core.database.AppDatabase
import com.eclinic.core.database.dao.ConsultationDao
import com.eclinic.core.database.dao.PatientDao
import com.eclinic.core.database.dao.VitalsDao
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import net.sqlcipher.database.SupportFactory
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideAppDatabase(
        @ApplicationContext context: Context
    ): AppDatabase {
        // In a production app, the passphrase should be retrieved from a secure source
        // like the Android Keystore. For now, we use a placeholder.
        val passphrase = "secure_passphrase_placeholder".toByteArray()
        val factory = SupportFactory(passphrase)

        return Room.databaseBuilder(
            context,
            AppDatabase::class.java,
            "eclinic.db"
        )
            .openHelperFactory(factory)
            .fallbackToDestructiveMigration()
            .build()
    }

    @Provides
    fun providePatientDao(database: AppDatabase): PatientDao = database.patientDao()

    @Provides
    fun provideConsultationDao(database: AppDatabase): ConsultationDao = database.consultationDao()

    @Provides
    fun provideVitalsDao(database: AppDatabase): VitalsDao = database.vitalsDao()
}
