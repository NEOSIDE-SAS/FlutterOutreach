@file:Suppress("UNCHECKED_CAST")

package com.flutter.flutter_outreach

import android.app.Activity
import android.app.AlertDialog
import android.app.DownloadManager
import android.content.*
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Environment
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.*
import java.net.HttpURLConnection
import java.net.URL


class UrlToDownload(var fileName: String, var urlPath: String, var bitmap: Bitmap?, var uri: Uri?)

/** FlutterOutreachPlugin */
class FlutterOutreachPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    companion object {
        private const val CACHE_DIRECTORY = "boucheron_asset/"
    }

    private var dialog: AlertDialog? = null

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var urls = listOf<Map<String, String>>()
    private var urlsToDownload = arrayOf<UrlToDownload>()
    private var item = 0
    private var method = ""
    private var result: Result? = null
    private var emailRecipient: Array<String>? = null
    private var message = ""
    private var phoneRecipient: Array<String>? = arrayOf("+3364546744")
    private var storagePermission: ExternalStoragePermissions = ExternalStoragePermissions()
    private var permissionsRegistry: PermissionsRegistry? = null

    private var br = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val uri = FileProvider.getUriForFile(
                activity!!,
                activity!!.applicationContext.packageName + ".provider",
                File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS).path + "/${urlsToDownload[item].fileName}")
            )
            urlsToDownload[item].uri = uri
            item += 1
            if (item == urlsToDownload.size) {
                dialog!!.dismiss()
                sendAsset()
            } else {
                downLoadMedia()
            }
        }

    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        setupCallbackChannels(flutterPluginBinding.binaryMessenger)
    }

    private fun setupCallbackChannels(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, "flutter_outreach")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        this.result = result
        initUrls(call)
        initEmails(call)
        if(urlsToDownload.isNotEmpty()) {
            initDialog()
        }
        method = call.method
        activity!!.registerReceiver(br, IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE))
        if (urlsToDownload.isNotEmpty()) {
            storagePermission.requestPermissions(
                activity!!,
                permissionsRegistry!!,
                object : ResultCallback {
                    override fun onResult(errorCode: String?, errorDescription: String?) {
                        if (errorCode == null) {
                            val thread = Thread {
                                try {
                                    downLoadMedia()
                                } catch (e: java.lang.Exception) {
                                    e.printStackTrace()
                                }
                            }
                            thread.start()
                        }
                    }
                }
            );
        } else {
            sendAsset()
        }


    }



    private fun sendAsset() {
        result!!.success( mapOf("outreachType" to "", "isSuccess" to true))
        when (method) {
            "sendSMS", "sendInstantMessaging" -> {
                share()
            }
            "sendEmail" -> {
                share(email = emailRecipient)
            }
            else -> return
        }
    }

    private fun initUrls(call: MethodCall) {
        urls = (call.arguments as Map<String, String>)["urls"] as List<Map<String, String>>
        urlsToDownload = arrayOf()
        item = 0
        for (url in urls) {
            urlsToDownload += UrlToDownload(
                fileName = url["fileName"] as String,
                urlPath = url["url"] as String,
                bitmap = null,
                uri = null
            )
        }
    }

    private fun initEmails(call: MethodCall) {
        if(call.method == "sendEmail") {
            emailRecipient =
                ((call.arguments as Map<String, String>)["recipients"] as List<String>).toTypedArray()
        }
    }

    private fun initDialog() {
        dialog = AlertDialog.Builder(activity).create()
        dialog!!.setTitle("Asset")
        dialog!!.setMessage("Downloading ...")
        dialog!!.setCanceledOnTouchOutside(false)
        dialog!!.show()
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    private fun share(email: Array<String>? = null) {
        val uris = getMediasUris()

        // Create the intent
        val intent = Intent(Intent.ACTION_SEND_MULTIPLE).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
            if (email != null) {
              putExtra(Intent.EXTRA_EMAIL, emailRecipient)
            }
            putExtra(Intent.EXTRA_TEXT, message)
            putExtra(Intent.EXTRA_PHONE_NUMBER, "+972587675677")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
            type = "*/*"
        }
        // Initialize the share chooser
        val chooserTitle = "Share assets!"
        val chooser = Intent.createChooser(intent, chooserTitle)
        val resInfoList: List<ResolveInfo> = activity!!.packageManager.queryIntentActivities(
            chooser,
            PackageManager.MATCH_DEFAULT_ONLY
        )

        for (uri in uris) {
            for (resolveInfo in resInfoList) {
                val packageName: String = resolveInfo.activityInfo.packageName
                activity!!.grantUriPermission(
                    packageName,
                    uri,
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_READ_URI_PERMISSION
                )
            }
        }

        activity!!.startActivity(chooser)

    }

    private fun getMediasUris(): ArrayList<Uri> {
        val uris = arrayListOf<Uri>()

        val cachePath = File(activity!!.externalCacheDir, CACHE_DIRECTORY)
        cachePath.mkdirs()

        for (urlToDownload in urlsToDownload) {
            if (!urlToDownload.fileName.contains(".mp4")) {
                val mediaFile = File(cachePath, urlToDownload.fileName).also { file ->
                    FileOutputStream(file).use { fileOutputStream ->
                        urlToDownload.bitmap?.compress(
                            Bitmap.CompressFormat.JPEG,
                            100,
                            fileOutputStream
                        )
                    }
                }.apply {
                    deleteOnExit()
                }

                val shareImageFileUri: Uri = FileProvider.getUriForFile(
                    activity!!,
                    activity!!.applicationContext.packageName + ".provider",
                    mediaFile
                )
                uris += shareImageFileUri
            } else if (urlToDownload.uri != null) {
                uris += (urlToDownload.uri)!!
            }
        }
        return uris
    }

    private fun downloadImage() {
        val inputStream: InputStream?
        val bmp: Bitmap?
        val responseCode: Int
        try {
            val url = URL(urlsToDownload[item].urlPath)
            val con = url.openConnection() as HttpURLConnection
            con.doInput = true
            con.connect()
            responseCode = con.responseCode
            if (responseCode == HttpURLConnection.HTTP_OK) {
                //download
                inputStream = con.inputStream
                bmp = BitmapFactory.decodeStream(inputStream)
                urlsToDownload[item].bitmap = bmp
                item += 1
                if (item == urlsToDownload.size) {
                    dialog?.dismiss()
                    sendAsset()
                } else {
                    downLoadMedia()
                }
                inputStream.close()
            }
        } catch (ex: Exception) {
            Log.e("Exception", ex.toString())
        }
    }

    private fun downloadVideo() {
        val request = DownloadManager.Request(Uri.parse(urlsToDownload[item].urlPath))
            .setTitle(urlsToDownload[item].fileName)
            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE)
            .setAllowedOverMetered(true)
        request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, urlsToDownload[item].fileName)
        request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)

        val dm = activity!!.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        dm.enqueue(request)
        request.setDestinationInExternalFilesDir(activity!!.applicationContext, "/file", urlsToDownload[item].fileName)

    }

    private fun downLoadMedia() {
        val thread = Thread {
            try {
                if(urlsToDownload[item].fileName.contains(".mp4")) {
                    downloadVideo()
                } else {
                    downloadImage()
                }
            } catch (e: java.lang.Exception) {
                e.printStackTrace()
            }
        }
        thread.start()
    }

}

