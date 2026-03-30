package com.eclinic.features.national.di

import com.eclinic.features.national.data.repository.NationalRepositoryImpl
import com.eclinic.features.national.domain.repository.NationalRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class NationalModule {

    @Binds
    @Singleton
    abstract fun bindNationalRepository(
        nationalRepositoryImpl: NationalRepositoryImpl
    ): NationalRepository
}
