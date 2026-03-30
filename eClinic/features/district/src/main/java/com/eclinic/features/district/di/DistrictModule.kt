package com.eclinic.features.district.di

import com.eclinic.features.district.data.repository.DistrictRepositoryImpl
import com.eclinic.features.district.domain.repository.DistrictRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class DistrictModule {

    @Binds
    @Singleton
    abstract fun bindDistrictRepository(
        districtRepositoryImpl: DistrictRepositoryImpl
    ): DistrictRepository
}
