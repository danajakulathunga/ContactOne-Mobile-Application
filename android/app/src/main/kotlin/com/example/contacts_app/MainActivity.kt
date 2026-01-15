package com.example.contacts_app

import android.content.Intent
import android.net.Uri
import android.provider.ContactsContract
import android.provider.DocumentsContract
import android.content.ContentResolver
import android.database.Cursor
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.contacts_app/import_export"
    private val REQUEST_PICK_CONTACTS = 1001
    private val REQUEST_EXPORT_FILE = 1002

    private var methodResult: MethodChannel.Result? = null
    private var pendingCSVContent: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickContacts" -> {
                        methodResult = result
                        pickContactsFromProvider()
                    }
                    "exportWithSAF" -> {
                        methodResult = result
                        val csvContent = call.argument<String>("csvContent")
                        val fileName = call.argument<String>("fileName") ?: "contacts_export.csv"
                        if (csvContent != null) {
                            pendingCSVContent = csvContent
                            exportWithSAF(fileName)
                        } else {
                            result.error("INVALID_ARGUMENT", "CSV content is required", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun pickContactsFromProvider() {
        val intent = Intent(Intent.ACTION_PICK, ContactsContract.Contacts.CONTENT_URI)
        intent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
        startActivityForResult(intent, REQUEST_PICK_CONTACTS)
    }

    private fun exportWithSAF(fileName: String) {
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "text/csv"
            putExtra(Intent.EXTRA_TITLE, fileName)
        }
        startActivityForResult(intent, REQUEST_EXPORT_FILE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        when (requestCode) {
            REQUEST_PICK_CONTACTS -> {
                if (resultCode == RESULT_OK && data != null) {
                    val contactsList = mutableListOf<Map<String, Any?>>()
                    
                    // Check if multiple contacts were selected
                    val clipData = data.clipData
                    if (clipData != null) {
                        // Multiple contacts selected
                        for (i in 0 until clipData.itemCount) {
                            val uri = clipData.getItemAt(i).uri
                            val contact = extractContactsFromUri(uri)
                            contactsList.add(contact)
                        }
                    } else {
                        // Single contact selected
                        val contactUri = data.data
                        if (contactUri != null) {
                            val contact = extractContactsFromUri(contactUri)
                            contactsList.add(contact)
                        }
                    }
                    
                    if (contactsList.isNotEmpty()) {
                        methodResult?.success(contactsList)
                    } else {
                        methodResult?.error("CANCELLED", "No contact selected", null)
                    }
                }
            }
            REQUEST_EXPORT_FILE -> {
                if (resultCode == RESULT_OK && data != null) {
                    val uri = data.data
                    if (uri != null && pendingCSVContent != null) {
                        try {
                            contentResolver.openOutputStream(uri)?.use { outputStream ->
                                outputStream.write(pendingCSVContent!!.toByteArray())
                            }
                            methodResult?.success(uri.toString())
                            pendingCSVContent = null
                        } catch (e: Exception) {
                            methodResult?.error("WRITE_ERROR", "Failed to write file: ${e.message}", null)
                        }
                    } else {
                        methodResult?.error("INVALID_URI", "Invalid URI returned", null)
                    }
                } else {
                    methodResult?.error("CANCELLED", "Export cancelled", null)
                }
            }
        }
    }

    private fun extractContactsFromUri(contactUri: Uri): Map<String, Any?> {
        val contactId = contactUri.lastPathSegment ?: ""
        val contact = mutableMapOf<String, Any?>()

        // Get contact name
        val nameCursor = contentResolver.query(
            contactUri,
            arrayOf(ContactsContract.Contacts.DISPLAY_NAME),
            null,
            null,
            null
        )
        nameCursor?.use {
            if (it.moveToFirst()) {
                contact["name"] = it.getString(0)
            }
        }

        // Get phone number
        val phoneCursor = contentResolver.query(
            ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
            arrayOf(
                ContactsContract.CommonDataKinds.Phone.NUMBER,
                ContactsContract.CommonDataKinds.Phone.TYPE
            ),
            "${ContactsContract.CommonDataKinds.Phone.CONTACT_ID} = ?",
            arrayOf(contactId),
            null
        )
        phoneCursor?.use {
            if (it.moveToFirst()) {
                contact["phoneNumber"] = it.getString(0)
            }
        }

        // Get email
        val emailCursor = contentResolver.query(
            ContactsContract.CommonDataKinds.Email.CONTENT_URI,
            arrayOf(
                ContactsContract.CommonDataKinds.Email.ADDRESS,
                ContactsContract.CommonDataKinds.Email.TYPE
            ),
            "${ContactsContract.CommonDataKinds.Email.CONTACT_ID} = ?",
            arrayOf(contactId),
            null
        )
        emailCursor?.use {
            if (it.moveToFirst()) {
                contact["email"] = it.getString(0)
            }
        }

        return contact
    }
}
