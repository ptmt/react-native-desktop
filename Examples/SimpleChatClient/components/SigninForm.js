/* @flow */
'use strict';

var React = require('React');
var ReactNative = require('react-native-desktop');;
var {
  View,
  Text,
  Animated,
  StyleSheet,
  TextInput,
  TouchableOpacity,
  TouchableHighlight,
  LinkingIOS,
  Image,
  Dimensions
} = ReactNative;

const AnimatedButton = Animated.createAnimatedComponent(TouchableHighlight);

class SigninForm extends React.Component {
  constructor() {
    super();
    this.state = {
      height: new Animated.Value(-1000),
      rotate: new Animated.Value(0.5),
      x: new Animated.Value(0),
      animatedColor: new Animated.Value(0),
      isButtonFocused: false
    };
  }
  componentDidMount() {
    Animated.sequence([
      Animated.delay(500),
      Animated.spring(this.state.height, {
        toValue: 0
      })
    ]).start();
  }
  componentWillReceiveProps(nextProps: any) {
    if (nextProps.isLoading && !this.props.isLoading) {
      this.pulse(false);
    }
    if (nextProps.error) {
      this.onError();
    }
  }
  pulse(back: boolean) {
    Animated.timing(this.state.animatedColor, {
      toValue: back ? 0 : 1,
      duration: 1000
    }).start(() => {
      if (this.props.isLoading) {
        setTimeout(() => this.pulse(!back), 500);
      }
    });
  }
  onError() {
    this.state.x.setValue(0)
    Animated.spring(this.state.x, {
      toValue: 1,
      friction: 5,
      tension: 300
    }).start();
  }
  render() {
    const animatedStyles = {
      transform: [{translateY: this.state.height}],
      left: this.state.x.interpolate({
       inputRange: [0, 0.5, 1],
       outputRange: [0, 20, 0]  // 0 : 150, 0.5 : 75, 1 : 0
     })};

    const rand = () => Math.floor(Math.random() * 255);
    const fromColors = [1, 2, 3].map(c => rand()).join(', ');
    const toColors = [1, 2, 3].map(c => rand()).join(', ');
    const animatedColor = this.state.animatedColor.interpolate({
        inputRange: [0, 1],
        outputRange: [
          'rgb(' + fromColors.toString() + ')',
          'rgb(' + toColors.toString() + ')'
        ]
    });

    return (
      <Image style={styles.container}
        source={{uri: 'https://images.unsplash.com/photo-1444703686981-a3abbc4d4fe3?dpr=2&fit=crop&fm=jpg&h=825&ixlib=rb-0.3.5&q=50&w=1450'}}
        resizeMode={Image.resizeMode.cover}>
        <Animated.View style={[styles.form, animatedStyles]}>
          <Text style={styles.header}>Simple Chat Client</Text>
          <View style={styles.input}>
            <Text style={styles.placeholder}>EMAIL</Text>
            <TextInput
              bezeled={false}
              style={styles.textinput}
              multiline={false}
              selectionColor={'white'}
              autoFocus={true}
              onChangeText={(username) => this.setState({username})}
            />
          </View>
          <View style={styles.input}>
            <Text style={styles.placeholder}>PASSWORD</Text>
            <TextInput
              bezeled={false}
              style={styles.textinput}
              multiline={false}
              password={true}
              selectionColor={'white'}
              onChangeText={(password) => this.setState({password})}
            />
          </View>
          <AnimatedButton
            style={[styles.button,
                this.props.isLoading ? {backgroundColor: animatedColor} : {},
                this.state.isButtonFocused ? { borderColor: 'white', borderWidth: 1} : { borderColor: '#009aff', borderWidth: 1}]
            }
            onPress={() => this.props.login(this.state.username, this.state.password)}
            tabIndex={3}
            onFocus={() => this.setState({isButtonFocused: true})}
            onBlur={() => this.setState({isButtonFocused: false})}
          >
            <Text style={styles.buttonCaption}>Sign in</Text>
          </AnimatedButton>
        </Animated.View>
        <View style={styles.footer} onFocus={() => console.log('Footer')}>
          <Text style={styles.footerText}>This app uses Discord unofficial APIs only for demonstration purposes.</Text>
        </View>
      </Image>
    );
  }

}

var styles = StyleSheet.create({
  container: {
    justifyContent: 'center',
    alignItems: 'center',
    flex: 1,
  },
  content: {
    width: 300,
    margin: 10,
    color: '#888',
    textAlign: 'center'
  },
  form: {
    padding: 20,
    backgroundColor: 'transparent',
    justifyContent: 'center',
    alignItems: 'center',
  },
  header: {
    fontSize: 30,
    color: 'white',
    marginBottom: 20,
    shadowColor: 'black',
    shadowOffset: {width: 1, height: 1},
    shadowOpacity: 1,
    shadowRadius: 1
  },
  button: {
    marginVertical: 20,
    backgroundColor: '#009aff',
    paddingVertical: 10,
    width: 250,
  },
  buttonCaption: {
    textAlign: 'center',
    color: 'white',
    fontSize: 20
  },
  textinput: {
    height: 25,
    borderWidth: 0,
    borderColor: '#0f0f0f',
    width: 250,
    fontSize: 16,
    color: 'white',
    backgroundColor: 'transparent'
  },
  input: {
    borderBottomWidth: 1,
    borderBottomColor: '#ccc',
    marginBottom: 20
  },
  placeholder: {
    color: '#eee',
    marginBottom: 5,
    shadowColor: 'black',
    shadowOffset: {width: 1, height: 1},
    shadowOpacity: 1,
    shadowRadius: 1
  },
  footer: {
    position: 'absolute',
    flex: 1,
    marginLeft: 50,
    top: 10 //TODO: why so? weird
  },
  footerText: {
    fontSize: 10,
    color: 'white'
  }
});
module.exports = SigninForm;
