#if defined _teftp_included_
	#endinput
#endif
#define _teftp_included_


functag EasyFTP_FileUploaded public(const String:sTarget[], const String:sLocalFile[], const String:sRemoteFile[], iErrorCode);
native EasyFTP_UploadFile(const String:sTarget[], const String:sLocalFile[], const String:sRemoteFile[], EasyFTP_FileUploaded:func);