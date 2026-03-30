package com.eclinic.features.nurse.di

import com.eclinic.features.nurse.data.repository.NurseRepositoryImpl
import com.eclinic.features.nurse.domain.repository.NurseRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class NurseModule {

    @Binds
    @Singleton
    abstract fun bindNurseRepository(
        nurseRepositoryImpl: NurseRepositoryImpl
    ): NurseRepository
}
