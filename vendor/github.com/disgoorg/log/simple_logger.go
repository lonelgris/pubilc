package log

import (
	"fmt"
	"log"
	"os"
)

var _ Logger = (*SimpleLogger)(nil)

var std = New(log.LstdFlags)

// These flags define which text to prefix to each Output entry generated by the Logger.
// Bits are or'ed together to control what's printed.
// Except the Lmsgprefix flag, there is no
// control over the order they appear (the order listed here)
// or the format they present (as described in the comments).
// The prefix is followed by a colon only when Llongfile or Lshortfile
// is specified.
// For example, flags Ldate | Ltime (or LstdFlags) produce,
//
//	2009/01/23 01:23:23 message
//
// while flags Ldate | Ltime | Lmicroseconds | Llongfile produce,
//
//	2009/01/23 01:23:23.123123 /a/b/c/d.go:23: message
const (
	Ldate         = 1 << iota     // the date in the local time zone: 2009/01/23
	Ltime                         // the time in the local time zone: 01:23:23
	Lmicroseconds                 // microsecond resolution: 01:23:23.123123.  assumes Ltime.
	Llongfile                     // full file name and line number: /a/b/c/d.go:23
	Lshortfile                    // final file name element and line number: d.go:23. overrides Llongfile
	LUTC                          // if Ldate or Ltime is set, use UTC rather than the local time zone
	Lmsgprefix                    // move the "prefix" from the beginning of the line to before the message
	LstdFlags     = Ldate | Ltime // initial values for the standard logger
)

// Level are different levels at which the SimpleLogger can Output
type Level int

// All Level(s) which SimpleLogger supports
const (
	LevelTrace Level = iota
	LevelDebug
	LevelInfo
	LevelWarn
	LevelError
	LevelFatal
	LevelPanic
)

// String returns the name of the Level
func (l Level) String() string {
	switch l {
	case LevelTrace:
		return "TRACE"
	case LevelDebug:
		return "DEBUG"
	case LevelInfo:
		return "INFO "
	case LevelWarn:
		return "WARN "
	case LevelError:
		return "ERROR"
	case LevelFatal:
		return "FATAL"
	case LevelPanic:
		return "PANIC"
	default:
		return ""
	}
}

var (
	EnableColors = true
	PrefixStyle  = ForegroundColorBrightBlack
	LevelStyle   = StyleBold
	TextStyle    = ForegroundColorWhite
)

var Styles = map[Level]Style{
	LevelTrace: ForegroundColorBrightBlack,
	LevelDebug: ForegroundColorWhite,
	LevelInfo:  ForegroundColorCyan,
	LevelWarn:  ForegroundColorYellow,
	LevelError: ForegroundColorBrightRed,
	LevelFatal: ForegroundColorRed,
	LevelPanic: ForegroundColorMagenta,
}

// SetLevelColor sets the Style of the given Level
func SetLevelColor(level Level, color Style) {
	Styles[level] = color
}

// Default returns the default SimpleLogger
func Default() *SimpleLogger {
	return std
}

// SetDefault sets the default SimpleLogger
func SetDefault(logger *SimpleLogger) {
	std = logger
}

// New returns a newInt SimpleLogger implementation
func New(flags int) *SimpleLogger {
	return &SimpleLogger{
		logger: log.New(os.Stderr, "", flags),
		level:  LevelInfo,
	}
}

// SimpleLogger is a wrapper for the std Logger
type SimpleLogger struct {
	logger *log.Logger
	level  Level
	prefix Style
}

// SetLevel sets the lowest Level to Output for
func (l *SimpleLogger) SetLevel(level Level) {
	l.level = level
}

// SetFlags sets the Output flags like: Ldate, Ltime, Lmicroseconds, Llongfile, Lshortfile, LUTC, Lmsgprefix,LstdFlags
func (l *SimpleLogger) SetFlags(flags int) {
	l.logger.SetFlags(flags)
}

func (l *SimpleLogger) Output(calldepth int, level Level, v ...any) {
	if level < l.level {
		return
	}

	if l.prefix != PrefixStyle {
		l.prefix = PrefixStyle
		l.logger.SetPrefix(PrefixStyle.String())
	}

	v = append(v, "", StyleReset)
	copy(v[2:], v)

	levelStr := level.String() + " "
	textStyleStr := ""
	endStyleStr := ""
	if EnableColors {
		levelStr = LevelStyle.And(Styles[level]).Apply(levelStr)
		textStyleStr = TextStyle.String()
		endStyleStr = StyleReset.String()
	}
	v[0] = levelStr
	v[1] = textStyleStr

	s := fmt.Sprint(v...) + endStyleStr
	switch level {
	case LevelFatal:
		_ = l.logger.Output(calldepth, s)
		os.Exit(1)
	case LevelPanic:
		_ = l.logger.Output(calldepth, s)
		panic(s)
	default:
		_ = l.logger.Output(calldepth, s)
	}
}

func (l *SimpleLogger) Outputf(calldepth int, level Level, format string, v ...any) {
	l.Output(calldepth+1, level, fmt.Sprintf(format, v...))
}

// Trace logs on the LevelTrace
func (l *SimpleLogger) Trace(v ...any) {
	l.Output(3, LevelTrace, v...)
}

// Tracef logs on the LevelTrace
func (l *SimpleLogger) Tracef(format string, v ...any) {
	l.Outputf(3, LevelTrace, format, v...)
}

// Debug logs on the LevelDebug
func (l *SimpleLogger) Debug(v ...any) {
	l.Output(3, LevelDebug, v...)
}

// Debugf logs on the LevelDebug
func (l *SimpleLogger) Debugf(format string, v ...any) {
	l.Outputf(3, LevelDebug, format, v...)
}

// Info logs on the LevelInfo
func (l *SimpleLogger) Info(v ...any) {
	l.Output(3, LevelInfo, v...)
}

// Infof logs on the LevelInfo
func (l *SimpleLogger) Infof(format string, v ...any) {
	l.Outputf(3, LevelInfo, format, v...)
}

// Warn logs on the LevelWarn
func (l *SimpleLogger) Warn(v ...any) {
	l.Output(3, LevelWarn, v...)
}

// Warnf logs on the LevelWarn
func (l *SimpleLogger) Warnf(format string, v ...any) {
	l.Outputf(3, LevelWarn, format, v...)
}

// Error logs on the LevelError
func (l *SimpleLogger) Error(v ...any) {
	l.Output(3, LevelError, v...)
}

// Errorf logs on the LevelError
func (l *SimpleLogger) Errorf(format string, v ...any) {
	l.Outputf(3, LevelError, format, v...)
}

// Fatal logs on the LevelFatal
func (l *SimpleLogger) Fatal(v ...any) {
	l.Output(3, LevelFatal, v...)
}

// Fatalf logs on the LevelFatal
func (l *SimpleLogger) Fatalf(format string, v ...any) {
	l.Outputf(3, LevelFatal, format, v...)
}

// Panic logs on the LevelPanic
func (l *SimpleLogger) Panic(v ...any) {
	l.Output(3, LevelPanic, v...)
}

// Panicf logs on the LevelPanic
func (l *SimpleLogger) Panicf(format string, v ...any) {
	l.Outputf(3, LevelPanic, format, v...)
}

// SetLevel sets the Level of the default Logger
func SetLevel(level Level) {
	Default().SetLevel(level)
}

// SetFlags sets the Output flags like: Ldate, Ltime, Lmicroseconds, Llongfile, Lshortfile, LUTC, Lmsgprefix,LstdFlags of the default Logger
func SetFlags(flags int) {
	Default().SetFlags(flags)
}

// Trace logs on the LevelTrace with the default SimpleLogger
func Trace(v ...any) {
	Output(3, LevelTrace, v...)
}

// Tracef logs on the LevelTrace with the default SimpleLogger
func Tracef(format string, v ...any) {
	Outputf(3, LevelTrace, format, v...)
}

// Debug logs on the LevelDebug with the default SimpleLogger
func Debug(v ...any) {
	Output(3, LevelDebug, v...)
}

// Debugf logs on the LevelDebug with the default SimpleLogger
func Debugf(format string, v ...any) {
	Outputf(3, LevelDebug, format, v...)
}

// Info logs on the LevelInfo with the default SimpleLogger
func Info(v ...any) {
	Output(3, LevelInfo, v...)
}

// Infof logs on the LevelInfo with the default SimpleLogger
func Infof(format string, v ...any) {
	Outputf(3, LevelInfo, format, v...)
}

// Warn logs on the LevelWarn with the default SimpleLogger
func Warn(v ...any) {
	Output(3, LevelWarn, v...)
}

// Warnf logs on the Level with the default SimpleLogger
func Warnf(format string, v ...any) {
	Outputf(3, LevelWarn, format, v...)
}

// Error logs on the LevelError with the default SimpleLogger
func Error(v ...any) {
	Output(3, LevelError, v...)
}

// Errorf logs on the LevelError with the default SimpleLogger
func Errorf(format string, v ...any) {
	Outputf(3, LevelError, format, v...)
}

// Fatal logs on the LevelFatal with the default SimpleLogger
func Fatal(v ...any) {
	Output(3, LevelFatal, v...)
}

// Fatalf logs on the LevelFatal with the default SimpleLogger
func Fatalf(format string, v ...any) {
	Outputf(3, LevelFatal, format, v...)
}

// Panic logs on the LevelPanic with the default SimpleLogger
func Panic(v ...any) {
	Output(3, LevelPanic, v...)
}

// Panicf logs on the LevelPanic with the default SimpleLogger
func Panicf(format string, v ...any) {
	Outputf(3, LevelPanic, format, v...)
}

func Output(calldepth int, level Level, v ...any) {
	std.Output(calldepth+1, level, v...)
}

func Outputf(calldepth int, level Level, format string, v ...any) {
	std.Outputf(calldepth+1, level, format, v...)
}