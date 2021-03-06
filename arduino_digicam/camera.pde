// カメラ通信
CameraC328R camera;

// 写真保存用
File picture;

// 最後に同期した時間
unsigned long lastSyncTime = 0;

void camera_sync(void)
{
  if(millis() - lastSyncTime > 5000){
    camera.sync();
    lastSyncTime = millis();
  }
}

void getJPEGPicture_callback( uint16_t pictureSize, uint16_t packageSize, uint16_t packageCount, byte* package )
{
  green(HIGH);
  picture.write(package, packageSize);
  green(LOW);
}

int photoNumber(void)
{
  int num;
  num = EEPROM.read(0);
  num |= EEPROM.read(1) << 8;
  return num;
}

void setPhotoNumber(int number)
{
  if( number > 9999 ){
    number = 0;
  }
  EEPROM.write(0,number & 0xff);
  EEPROM.write(1,number >> 8);  
}

bool getJPEGPicture(void)
{
  int photoNo;
  uint16_t pictureSize = 0;
  char buf[12];

  if( !camera.sync() ){
    goto camera_error;
  }

  if( !camera.initial( CameraC328R::CT_JPEG, CameraC328R::PR_160x120, CameraC328R::JR_640x480 ) ){
    goto camera_error;
  }

  if( !camera.setPackageSize( 100 ) ){
    goto camera_error;
  }

  if( !camera.setLightFrequency( CameraC328R::FT_50Hz ) ){
    goto camera_error;
  }

  attention(HIGH);
  if( !camera.snapshot( CameraC328R::ST_COMPRESSED, 0 ) ){
    goto camera_error;
  }
  attention(LOW);

  photoNo = photoNumber();
  setPhotoNumber(photoNo + 1);

  snprintf(buf, sizeof(buf), "/%04d", photoNo & 0xff00);
  FatFs.changeDirectory("/");
  FatFs.createDirectory(&buf[1]);// skip '/'

  if( !FatFs.changeDirectory(buf) ){
    goto camera_error;
  }

  snprintf(buf, sizeof(buf), "IMG%04d.jpg", photoNo);
  if( !FatFs.createFile(buf) ){
    goto camera_error;
  }

  if( !picture.open(buf) ){
    goto camera_error;
  }

  if( !camera.getJPEGPictureSize( CameraC328R::PT_SNAPSHOT, PROCESS_DELAY, pictureSize) ){
    goto camera_error;
  }

  picture.resize(pictureSize);

  if( !camera.getJPEGPictureData( &getJPEGPicture_callback) ){
    goto camera_error;
  }

  picture.close();
  return true;

  {
camera_error:
    picture.close();
    return false;
  }
}






