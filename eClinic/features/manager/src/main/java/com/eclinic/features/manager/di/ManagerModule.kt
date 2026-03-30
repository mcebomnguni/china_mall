package com.eclinic.features.manager.di

import com.eclinic.features.manager.data.repository.ManagerRepositoryImpl
import com.eclinic.features.manager.domain.repository.ManagerRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class ManagerModule {

    @Binds
    @Singleton
    abstract fun bindManagerRepository(
        managerRepositoryImpl: ManagerRepositoryImpl
    ): ManagerRepository
}
