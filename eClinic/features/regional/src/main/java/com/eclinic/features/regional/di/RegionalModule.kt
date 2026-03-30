package com.eclinic.features.regional.di

import com.eclinic.features.regional.data.repository.RegionalRepositoryImpl
import com.eclinic.features.regional.domain.repository.RegionalRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class RegionalModule {

    @Binds
    @Singleton
    abstract fun bindRegionalRepository(
        regionalRepositoryImpl: RegionalRepositoryImpl
    ): RegionalRepository
}
