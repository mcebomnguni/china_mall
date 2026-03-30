package com.eclinic.core.documents

import android.content.Context
import com.eclinic.core.common.model.Prescription
import com.tomroush.pdfbox.pdmodel.PDDocument
import com.tomroush.pdfbox.pdmodel.PDPage
import com.tomroush.pdfbox.pdmodel.PDPageContentStream
import com.tomroush.pdfbox.pdmodel.font.PDType1Font
import com.tomroush.pdfbox.util.PDFBoxResourceLoader
import dagger.hilt.android.qualifiers.ApplicationContext
import java.io.File
import java.text.SimpleDateFormat
import java.util.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class DocumentGenerator @Inject constructor(
    @ApplicationContext private val context: Context
) {

    init {
        PDFBoxResourceLoader.init(context)
    }

    fun generatePrescriptionPdf(prescription: Prescription): File {
        val document = PDDocument()
        val page = PDPage()
        document.addPage(page)

        val contentStream = PDPageContentStream(document, page)
        
        // Header
        contentStream.beginText()
        contentStream.setFont(PDType1Font.HELVETICA_BOLD, 18f)
        contentStream.newLineAtOffset(50f, 750f)
        contentStream.showText("eClinic - Prescription")
        contentStream.endText()

        // Details
        contentStream.beginText()
        contentStream.setFont(PDType1Font.HELVETICA, 12f)
        contentStream.newLineAtOffset(50f, 720f)
        contentStream.showText("Prescription ID: ${prescription.prescriptionId}")
        contentStream.newLineAtOffset(0f, -15f)
        val dateStr = SimpleDateFormat("dd MMM yyyy", Locale.getDefault()).format(Date(prescription.dateIssued))
        contentStream.showText("Date: $dateStr")
        contentStream.newLineAtOffset(0f, -15f)
        contentStream.showText("Doctor ID: ${prescription.doctorId}")
        contentStream.newLineAtOffset(0f, -15f)
        contentStream.showText("Patient ID: ${prescription.patientId}")
        contentStream.endText()

        // Medications
        var yOffset = 640f
        contentStream.beginText()
        contentStream.setFont(PDType1Font.HELVETICA_BOLD, 14f)
        contentStream.newLineAtOffset(50f, yOffset)
        contentStream.showText("Medications:")
        contentStream.endText()
        yOffset -= 20f

        prescription.items.forEach { item ->
            contentStream.beginText()
            contentStream.setFont(PDType1Font.HELVETICA, 12f)
            contentStream.newLineAtOffset(60f, yOffset)
            contentStream.showText("${item.medication.name} (${item.medication.strength})")
            contentStream.newLineAtOffset(0f, -15f)
            contentStream.showText("Dosage: ${item.dosage} | Freq: ${item.frequency} | Dur: ${item.duration}")
            contentStream.endText()
            yOffset -= 40f
        }

        contentStream.close()

        val fileName = "Prescription_${prescription.prescriptionId}.pdf"
        val file = File(context.cacheDir, fileName)
        document.save(file)
        document.close()

        return file
    }
}
