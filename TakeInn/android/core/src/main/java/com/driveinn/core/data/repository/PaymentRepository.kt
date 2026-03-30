package com.driveinn.core.data.repository

import com.driveinn.core.data.model.PaymentInitiationRequest
import com.driveinn.core.data.model.PaymentInitiationResponse

interface PaymentRepository {
    suspend fun initiatePayment(request: PaymentInitiationRequest): PaymentInitiationResponse
}
