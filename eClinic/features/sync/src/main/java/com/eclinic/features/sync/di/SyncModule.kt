package com.eclinic.features.sync.di

import com.eclinic.features.sync.data.repository.SyncRepositoryImpl
import com.eclinic.features.sync.domain.repository.SyncRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class SyncModule {

    @Binds
    @Singleton
    abstract fun bindSyncRepository(syncRepositoryImpl: SyncRepositoryImpl): SyncRepository
}
