// 0713 trial-----------------------------------------------
/*
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SliderScreen(),
    );
  }
}
*/

class SliderScreen extends StatefulWidget {
  @override
  _SliderScreenState createState() => _SliderScreenState();
}

class _SliderScreenState extends State<SliderScreen> {
  double _sliderValue = 0.0;
  int _count = 0;
  bool _showText = false;
  bool _flash = false;
  Timer? _timer;
  Timer? _flashTimer;

  void _resetCounter() {
    setState(() {
      _count = 0;
      _showText = false;
    });
  }

  void _onSliderChanged(double value) {
    setState(() {
      _sliderValue = value;
      if (_sliderValue == 100) {
        if (_timer == null || !_timer!.isActive) {
          _timer = Timer(Duration(seconds: 30), _resetCounter);
        }
        _count++;
      }
      if (_count >= 3) {
        _showText = true;
        _timer?.cancel();
        _flashScreen();
      }
    });
  }

  void _flashScreen() {
    int flashCount = 0;
    _flashTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      setState(() {
        _flash = !_flash;
      });
      flashCount++;
      if (flashCount >= 6) {
        timer.cancel();
        setState(() {
          _flash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _flash ? Colors.white : Colors.black,
      appBar: AppBar(
        title: Text('Slider Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Slider(
              value: _sliderValue,
              min: 0,
              max: 100,
              onChanged: _onSliderChanged,
            ),
            Text(
              'Slider Value: ${_sliderValue.toStringAsFixed(1)}',
              style: TextStyle(color: _flash ? Colors.black : Colors.white),
            ),
            if (_showText)
              Text(
                '30秒以内に3回100になりました!',
                style: TextStyle(fontSize: 24, color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }


}