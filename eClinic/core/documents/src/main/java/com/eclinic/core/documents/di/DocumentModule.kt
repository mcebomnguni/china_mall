package com.eclinic.core.documents.di

import android.content.Context
import com.eclinic.core.documents.DocumentGenerator
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DocumentModule {

    @Provides
    @Singleton
    fun provideDocumentGenerator(
        @ApplicationContext context: Context
    ): DocumentGenerator {
        return DocumentGenerator(context)
    }
}
