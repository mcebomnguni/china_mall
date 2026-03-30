package com.eclinic.features.admin.di

import com.eclinic.features.admin.data.repository.AdminRepositoryImpl
import com.eclinic.features.admin.domain.repository.AdminRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class AdminModule {

    @Binds
    @Singleton
    abstract fun bindAdminRepository(
        adminRepositoryImpl: AdminRepositoryImpl
    ): AdminRepository
}
