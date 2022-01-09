const path = require('path');
const slsw = require('serverless-webpack')
const isVscodeDebuggingEnabled = !!process.env['VSCODE_DEBUG']

module.exports = {
  mode: slsw.lib.webpack.isLocal ? 'development' : 'production',
  entry: slsw.lib.entries,
  devtool: isVscodeDebuggingEnabled ? 'source-map' : 'eval',
  target: 'node',
  module: {
    rules: [
      {
        test: /\.tsx?$/,
        use: 'ts-loader',
        exclude: /node_modules/,
      },
    ],
  },
  resolve: {
    extensions: ['.tsx', '.ts', '.js'],
  },
  output: {
    library: {
      type: 'commonjs'
    },
    filename: '[name].js',
    path: path.resolve(__dirname, '.webpack'),
  },
};