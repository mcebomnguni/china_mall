package com.eclinic.features.provincial.di

import com.eclinic.features.provincial.data.repository.ProvincialRepositoryImpl
import com.eclinic.features.provincial.domain.repository.ProvincialRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class ProvincialModule {

    @Binds
    @Singleton
    abstract fun bindProvincialRepository(
        provincialRepositoryImpl: ProvincialRepositoryImpl
    ): ProvincialRepository
}
