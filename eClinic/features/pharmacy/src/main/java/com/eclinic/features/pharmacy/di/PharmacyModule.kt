package com.eclinic.features.pharmacy.di

import com.eclinic.features.pharmacy.data.repository.PharmacyRepositoryImpl
import com.eclinic.features.pharmacy.domain.repository.PharmacyRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class PharmacyModule {

    @Binds
    @Singleton
    abstract fun bindPharmacyRepository(
        pharmacyRepositoryImpl: PharmacyRepositoryImpl
    ): PharmacyRepository
}
