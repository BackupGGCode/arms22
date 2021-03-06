// １サイクルあたりのサンプル数
#define NUMBER_OF_SAMPLES (25)

// サンプリング間隔(マイクロ秒)
#define SAMPLING_PERIOD   (1000000/(PWRLINE_FREQ * NUMBER_OF_SAMPLES))

// サンプリング用バッファ
int VASamples[NUMBER_OF_SAMPLES*4];

void calcWatt (WattSample &sample, int ctPin, int vtPin)
{
  unsigned long t1,t2;
  int i,r,v1,a1,a2,v2;

  t1 = micros();

  // １サイクル分のAD値をサンプリング
  for(i=0; i<NUMBER_OF_SAMPLES; i++){

    r  = analogRead(arefPin);
    v1 = analogRead(vtPin);
    a1 = analogRead(ctPin);
    a2 = analogRead(ctPin);
    v2 = analogRead(vtPin);

    VASamples[(i*4)+0] = v1 - r;
    VASamples[(i*4)+1] = a1 - r;
    VASamples[(i*4)+2] = a2 - r;
    VASamples[(i*4)+3] = v2 - r;

    do {
      t2 = micros();
    } 
    while((t2 - t1) < SAMPLING_PERIOD);
    t1 += SAMPLING_PERIOD;
  }

  // １サイクル分の電圧と電流、電力を加算
  float vrms = 0;
  float irms = 0;
  float watt = 0;

  for(i=0; i<NUMBER_OF_SAMPLES; i++){
    v1 = VASamples[(i*4)+0];
    a1 = VASamples[(i*4)+1];
    a2 = VASamples[(i*4)+2];
    v2 = VASamples[(i*4)+3];

    float vv = ((((v1+v2)/2) * 5.0) / 1024) * kVT;
    float aa = ((((a1+a2)/2) * 5.0) / 1024) / kCT;

    vrms += vv * vv;
    irms += aa * aa;
    watt += vv * aa;
  }
  
  // 2乗平均平方根(rms)を求める
  vrms = sqrt(vrms / NUMBER_OF_SAMPLES);
  irms = sqrt(irms / NUMBER_OF_SAMPLES);
  
  // 平均電力を求める
  watt = watt / NUMBER_OF_SAMPLES;
  
  // 値を格納
  setSample(sample, vrms, irms, watt);
}
