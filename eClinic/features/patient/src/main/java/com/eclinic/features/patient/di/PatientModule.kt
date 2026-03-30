package com.eclinic.features.patient.di

import com.eclinic.features.patient.data.repository.PatientRepositoryImpl
import com.eclinic.features.patient.domain.repository.PatientRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class PatientModule {

    @Binds
    @Singleton
    abstract fun bindPatientRepository(
        patientRepositoryImpl: PatientRepositoryImpl
    ): PatientRepository
}
