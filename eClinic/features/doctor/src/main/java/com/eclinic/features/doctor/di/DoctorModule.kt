package com.eclinic.features.doctor.di

import com.eclinic.features.doctor.data.repository.DoctorDashboardRepositoryImpl
import com.eclinic.features.doctor.domain.repository.DoctorDashboardRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class DoctorModule {

    @Binds
    @Singleton
    abstract fun bindDoctorDashboardRepository(
        doctorDashboardRepositoryImpl: DoctorDashboardRepositoryImpl
    ): DoctorDashboardRepository
}
