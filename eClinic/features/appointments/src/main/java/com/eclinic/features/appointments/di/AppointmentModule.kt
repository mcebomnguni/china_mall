package com.eclinic.features.appointments.di

import com.eclinic.features.appointments.data.repository.AppointmentRepositoryImpl
import com.eclinic.features.appointments.domain.repository.AppointmentRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class AppointmentModule {

    @Binds
    @Singleton
    abstract fun bindAppointmentRepository(
        appointmentRepositoryImpl: AppointmentRepositoryImpl
    ): AppointmentRepository
}
