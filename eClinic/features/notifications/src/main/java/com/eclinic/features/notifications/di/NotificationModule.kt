package com.eclinic.features.notifications.di

import android.content.Context
import com.eclinic.features.notifications.EClinicNotificationHandler
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object NotificationModule {

    @Provides
    @Singleton
    fun provideNotificationHandler(
        @ApplicationContext context: Context
    ): EClinicNotificationHandler {
        return EClinicNotificationHandler(context)
    }
}
