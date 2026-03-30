package com.eclinic.features.sync.domain.repository

interface SyncRepository {
    suspend fun sync(): Result<Unit>
}
