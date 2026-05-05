import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image/image.dart' as img;
import 'package:latlong2/latlong.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_controller.dart';
import 'app_data.dart';
import 'models.dart';

const _canvas = Color(0xFFF6F0E8);
const _surface = Color(0xFFFFFCF8);
const _card = Color(0xFFFFFFFF);
const _ink = Color(0xFF231815);
const _muted = Color(0xFF6D625C);
const _coral = Color(0xFFD64045);
const _coralDark = Color(0xFF8F1D26);
const _gold = Color(0xFFE6AF57);
const _olive = Color(0xFF65743A);
const _line = Color(0xFFE8D7C8);
const _brandRed = Color(0xFFD90404);
const _brandRedDark = Color(0xFF9E1111);
const _availabilityValidationPhone = '3008468223';
const _pastoCenter = LatLng(1.2136, -77.2811);
const _googleServerClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
  defaultValue:
      '478280895188-s39qhiifrjshj3i5er1ehcpfp2n17h1l.apps.googleusercontent.com',
);
const _guidedRecommendationOptions = <String>[
  'Delicioso',
  'A tiempo',
  'Recien salido del horno',
  'Crujio bonito',
  'Porcion generosa',
  'Sabor que impone respeto',
];

class LaCartaApp extends StatelessWidget {
  const LaCartaApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _coral,
        brightness: Brightness.light,
        surface: _surface,
      ),
      scaffoldBackgroundColor: _canvas,
      textTheme: GoogleFonts.manropeTextTheme(),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'La Carta',
      theme: base.copyWith(
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.sora(
            color: _ink,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        cardTheme: CardThemeData(
          color: _card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: const BorderSide(color: _line),
          ),
        ),
        chipTheme: base.chipTheme.copyWith(
          selectedColor: _coral,
          secondarySelectedColor: _coral,
          side: const BorderSide(color: _line),
          backgroundColor: _surface,
          labelStyle: GoogleFonts.manrope(
            color: _ink,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: _surface,
          height: 66,
          indicatorColor: _coral.withValues(alpha: 0.14),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected) ? _coral : _muted,
              size: 21,
            ),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => GoogleFonts.manrope(
              color: states.contains(WidgetState.selected) ? _coral : _muted,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _coral,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            textStyle: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _ink,
            side: const BorderSide(color: _line),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            textStyle: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
      ),
      home: SplashGate(controller: controller),
    );
  }
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.controller});

  final AppController controller;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  var _ready = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _ready = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _ready
              ? (widget.controller.isAuthenticated
                    ? LaCartaHomeShell(controller: widget.controller)
                    : AuthScreen(controller: widget.controller))
              : const _SplashScreen(),
        );
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  GoogleSignIn? _googleSignIn;
  GoogleSignIn _getGoogleSignIn() {
    return _googleSignIn ??= GoogleSignIn(
      scopes: const ['email'],
      clientId: _googleServerClientId.isEmpty ? null : _googleServerClientId,
      serverClientId:
          _googleServerClientId.isEmpty ? null : _googleServerClientId,
    );
  }

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  var _isPasswordObscured = true;
  var _isConfirmPasswordObscured = true;
  var _showConfirmPasswordError = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_handlePasswordInputsChanged);
    _confirmPasswordController.addListener(_handlePasswordInputsChanged);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_handlePasswordInputsChanged);
    _confirmPasswordController.removeListener(_handlePasswordInputsChanged);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handlePasswordInputsChanged() {
    if (!mounted) {
      return;
    }
    setState(() {
      if (_showConfirmPasswordError &&
          _confirmPasswordController.text == _passwordController.text) {
        _showConfirmPasswordError = false;
      }
    });
  }

  Future<void> _handleEmailRegister() async {
    await widget.controller.register(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      phone: _phoneController.text,
    );

    if (!mounted) {
      return;
    }

    final pendingEmail = widget.controller.pendingEmailVerificationEmail;
    if (pendingEmail != null && pendingEmail.isNotEmpty) {
      await _showEmailVerificationSheet(
        context,
        controller: widget.controller,
        initialEmail: pendingEmail,
      );
    }
  }

  Future<void> _handleGoogleAuth() async {
    try {
      widget.controller.clearAuthFeedback();
      final googleSignIn = _getGoogleSignIn();
      await googleSignIn.signOut();
      final account = await googleSignIn.signIn();
      if (account == null) {
        return;
      }

      final authentication = await account.authentication;
      final idToken = authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo obtener el token de Google.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      await widget.controller.signInWithGoogle(
        idToken: idToken,
        phone: _phoneController.text,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.authErrorMessage?.isNotEmpty == true
                ? widget.controller.authErrorMessage!
                : 'No se pudo iniciar sesión con Google.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final isRegister = widget.controller.isRegisterMode;
        final showConfirmPasswordError =
          isRegister &&
          (_showConfirmPasswordError ||
            _confirmPasswordController.text.isNotEmpty) &&
          _confirmPasswordController.text != _passwordController.text;
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  children: [
                const LaCartaBannerCard(
                  height: 148,
                  imageAsset: 'images/logo_la_carta-01.png',
                  imageWidthFactor: 0.56,
                ),
                const SizedBox(height: 22),
                Text(
                  isRegister ? 'Crea tu cuenta' : 'Bienvenido a La Carta',
                  style: GoogleFonts.sora(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                    fontSize: MediaQuery.sizeOf(context).width < 380 ? 24 : 28,
                  ),
                ),
                const SizedBox(height: 18),
                if (isRegister) ...[
                  TextField(
                    controller: _nameController,
                    decoration: _inputDecoration(
                      'Nombre completo',
                      Icons.person_rounded,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration(
                      'Número de WhatsApp',
                      Icons.phone_rounded,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                    'Correo electrónico',
                    Icons.alternate_email_rounded,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: _isPasswordObscured,
                  decoration: _inputDecoration(
                    'Contraseña',
                    Icons.lock_rounded,
                  ).copyWith(
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _isPasswordObscured = !_isPasswordObscured;
                        });
                      },
                      icon: Icon(
                        _isPasswordObscured
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        color: _muted,
                      ),
                      tooltip: _isPasswordObscured
                          ? 'Mostrar contraseña'
                          : 'Ocultar contraseña',
                    ),
                  ),
                ),
                if (isRegister) ...[
                  const SizedBox(height: 10),
                  _PasswordStrengthBar(password: _passwordController.text),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _isConfirmPasswordObscured,
                    decoration: _inputDecoration(
                      'Confirmar contraseña',
                      Icons.verified_user_rounded,
                    ).copyWith(
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordObscured =
                                !_isConfirmPasswordObscured;
                          });
                        },
                        icon: Icon(
                          _isConfirmPasswordObscured
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: _muted,
                        ),
                        tooltip: _isConfirmPasswordObscured
                            ? 'Mostrar contraseña'
                            : 'Ocultar contraseña',
                      ),
                    ),
                  ),
                  if (showConfirmPasswordError) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        'Las contraseñas no coinciden.',
                        style: GoogleFonts.manrope(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
                if (widget.controller.authErrorMessage != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Text(
                      widget.controller.authErrorMessage!,
                      style: GoogleFonts.manrope(
                        color: Colors.red.shade800,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                if (widget.controller.authInfoMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7E8),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFF0D7A8)),
                    ),
                    child: Text(
                      widget.controller.authInfoMessage!,
                      style: GoogleFonts.manrope(
                        color: _ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: widget.controller.isAuthBusy ? null : () async {
                    if (isRegister) {
                      if (_confirmPasswordController.text !=
                          _passwordController.text) {
                        setState(() {
                          _showConfirmPasswordError = true;
                        });
                        return;
                      }

                      await _handleEmailRegister();
                    } else {
                      await widget.controller.signIn(
                        email: _emailController.text,
                        password: _passwordController.text,
                      );
                    }
                  },
                  icon: Icon(
                    isRegister
                        ? Icons.person_add_alt_1_rounded
                        : Icons.login_rounded,
                  ),
                  label: Text(
                    widget.controller.isAuthBusy
                        ? 'Validando...'
                        : (isRegister ? 'Crear cuenta' : 'Ingresar'),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: widget.controller.isAuthBusy
                      ? null
                      : () {
                          setState(() {
                            _showConfirmPasswordError = false;
                            _confirmPasswordController.clear();
                          });
                          widget.controller.clearAuthFeedback();
                          widget.controller.toggleAuthMode();
                        },
                  child: Text(
                    isRegister
                        ? 'Ya tengo cuenta, iniciar sesión'
                        : 'No tengo cuenta, registrarme',
                  ),
                ),
                const SizedBox(height: 14),
                _AuthProviderActions(
                  isRegister: isRegister,
                  onGoogleTap:
                      widget.controller.isAuthBusy ? null : _handleGoogleAuth,
                ),
                if (widget.controller.pendingEmailVerificationEmail != null) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: widget.controller.isAuthBusy
                        ? null
                        : () => _showEmailVerificationSheet(
                              context,
                              controller: widget.controller,
                              initialEmail:
                                  widget.controller.pendingEmailVerificationEmail!,
                            ),
                    icon: const Icon(Icons.mark_email_read_rounded),
                    label: const Text('Ingresar codigo de verificacion'),
                  ),
                ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  const _PasswordStrengthBar({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final strength = _passwordStrength(password);

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 128,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: strength.progress,
            minHeight: 4,
            backgroundColor: _line,
            valueColor: AlwaysStoppedAnimation<Color>(strength.color),
          ),
        ),
      ),
    );
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _drawProgress;
  late final Animation<double> _fillOpacity;
  late final Future<_ParsedSvgLogo> _logoFuture;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _drawProgress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _fillOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.68, 1, curve: Curves.easeOutCubic),
    );
    _logoFuture = _loadSplashLogo();
    unawaited(_controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<_ParsedSvgLogo> _loadSplashLogo() async {
    const assetPath = 'images/logo la carta-01.svg';
    final rawSvg = await rootBundle.loadString(assetPath);
    final viewBoxMatch = RegExp(
      r'viewBox="([0-9.-]+)	*\s+([0-9.-]+)	*\s+([0-9.-]+)	*\s+([0-9.-]+)"',
    ).firstMatch(rawSvg);

    final minX = double.tryParse(viewBoxMatch?.group(1) ?? '') ?? 0;
    final minY = double.tryParse(viewBoxMatch?.group(2) ?? '') ?? 0;
    final width = double.tryParse(viewBoxMatch?.group(3) ?? '') ?? 1000;
    final height = double.tryParse(viewBoxMatch?.group(4) ?? '') ?? 1000;
    final translateMatrix = Matrix4.translationValues(-minX, -minY, 0);

    final matches = RegExp(
      r'<path[^>]*d="([^"]+)"',
      caseSensitive: false,
    ).allMatches(rawSvg);

    final paths = matches
        .map((match) => parseSvgPathData(match.group(1)!))
        .map((path) => path.transform(translateMatrix.storage))
        .where((path) => !path.getBounds().isEmpty)
        .toList(growable: false);

    return _ParsedSvgLogo(
      viewBox: Size(width, height),
      paths: paths,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _coral,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_coral, _coralDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SizedBox(
            width: 228,
            height: 228,
            child: FutureBuilder<_ParsedSvgLogo>(
              future: _logoFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _SplashLogoPainter(
                        logo: snapshot.data!,
                        drawProgress: _drawProgress.value,
                        fillOpacity: _fillOpacity.value,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ParsedSvgLogo {
  const _ParsedSvgLogo({required this.viewBox, required this.paths});

  final Size viewBox;
  final List<ui.Path> paths;
}

class _SplashLogoPainter extends CustomPainter {
  const _SplashLogoPainter({
    required this.logo,
    required this.drawProgress,
    required this.fillOpacity,
  });

  final _ParsedSvgLogo logo;
  final double drawProgress;
  final double fillOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (logo.paths.isEmpty || size.isEmpty) {
      return;
    }

    final fitted = applyBoxFit(BoxFit.contain, logo.viewBox, size);
    final source = Alignment.center.inscribe(fitted.source, Offset.zero & logo.viewBox);
    final destination = Alignment.center.inscribe(fitted.destination, Offset.zero & size);

    canvas.save();
    canvas.translate(destination.left, destination.top);
    canvas.scale(
      destination.width / source.width,
      destination.height / source.height,
    );
    canvas.translate(-source.left, -source.top);

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: fillOpacity);
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    var totalLength = 0.0;
    final pathMetrics = <ui.PathMetric>[];
    for (final path in logo.paths) {
      for (final metric in path.computeMetrics()) {
        pathMetrics.add(metric);
        totalLength += metric.length;
      }
    }

    final targetLength = totalLength * drawProgress;
    var consumed = 0.0;
    final tracedPath = ui.Path();

    for (final metric in pathMetrics) {
      if (consumed >= targetLength) {
        break;
      }

      final remaining = targetLength - consumed;
      final extractLength = math.min(metric.length, remaining);
      tracedPath.addPath(metric.extractPath(0, extractLength), Offset.zero);
      consumed += extractLength;
    }

    if (fillOpacity > 0) {
      for (final path in logo.paths) {
        canvas.drawPath(path, fillPaint);
      }
    }

    canvas.drawPath(tracedPath, strokePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SplashLogoPainter oldDelegate) {
    return oldDelegate.drawProgress != drawProgress ||
        oldDelegate.fillOpacity != fillOpacity ||
        oldDelegate.logo != logo;
  }
}

class LaCartaHomeShell extends StatefulWidget {
  const LaCartaHomeShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<LaCartaHomeShell> createState() => _LaCartaHomeShellState();
}

class _LaCartaHomeShellState extends State<LaCartaHomeShell> {
  bool _noticeScheduled = false;

  @override
  void initState() {
    super.initState();
    _scheduleRecommendationNotice();
  }

  void _scheduleRecommendationNotice() {
    if (_noticeScheduled) {
      return;
    }
    _noticeScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !widget.controller.shouldShowRecommendationNotice) {
        return;
      }

      var doNotShowAgain = false;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                title: Text(
                  'Recomienda desde tu pedido',
                  style: GoogleFonts.sora(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Las recomendaciones nacen de pedidos entregados. Si la experiencia fue buena, pasa al feed como recomendación verificada y otros usuarios solo pueden darle corazón.',
                      style: GoogleFonts.manrope(
                        color: _muted,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: _coral.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.thumb_up_alt_rounded,
                            color: _coral,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.controller.pendingRecommendationCount > 0
                                ? 'Tienes ${widget.controller.pendingRecommendationCount} pedido${widget.controller.pendingRecommendationCount == 1 ? '' : 's'} listo${widget.controller.pendingRecommendationCount == 1 ? '' : 's'} para recomendar.'
                                : 'Cuando completes un pedido podrás decidir si lo recomiendas o no.',
                            style: GoogleFonts.sora(
                              color: _ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: doNotShowAgain,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: _coral,
                      title: Text(
                        'No volver a mostrar',
                        style: GoogleFonts.manrope(
                          color: _ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          doNotShowAgain = value ?? false;
                        });
                      },
                    ),
                  ],
                ),
                actions: [
                  FilledButton(
                    onPressed: () async {
                      await widget.controller.setHideRecommendationNotice(
                        doNotShowAgain,
                      );
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    },
                    child: const Text('Aceptar'),
                  ),
                ],
              );
            },
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final radius = MediaQuery.sizeOf(context).width > 720 ? 34.0 : 0.0;
        return Stack(
          children: [
            const Positioned.fill(
              child: ColoredBox(color: Colors.white),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.18,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('images/backgroundapp.png'),
                      repeat: ImageRepeat.repeat,
                      alignment: Alignment.topLeft,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),
              ),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0x33FAF4EC), Color(0x26FFFFFF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(radius),
                      child: Material(
                        color: Colors.transparent,
                        child: Stack(
                          children: [
                            Scaffold(
                              backgroundColor: Colors.transparent,
                              floatingActionButton:
                                  widget.controller.cartCount > 0
                                      ? FloatingActionButton.extended(
                                          onPressed: () => Navigator.of(context)
                                              .push(
                                                MaterialPageRoute<void>(
                                                  builder: (_) => CartScreen(
                                                    controller: widget.controller,
                                                  ),
                                                ),
                                              ),
                                          backgroundColor: _coral,
                                          foregroundColor: Colors.white,
                                          icon: const Icon(
                                              Icons.shopping_bag_rounded),
                                          label: Text(
                                            '${widget.controller.cartCount} · ${_currency(widget.controller.cartTotal)}',
                                          ),
                                        )
                                      : null,
                              bottomNavigationBar: NavigationBar(
                                selectedIndex:
                                    widget.controller.selectedTabIndex,
                                onDestinationSelected: widget.controller.setTab,
                                destinations: const [
                                  NavigationDestination(
                                    icon: Icon(Icons.home_rounded),
                                    label: 'Home',
                                  ),
                                  NavigationDestination(
                                    icon: Icon(Icons.storefront_rounded),
                                    label: 'Restaurantes',
                                  ),
                                  NavigationDestination(
                                    icon:
                                        Icon(Icons.play_circle_fill_rounded),
                                    label: 'Social',
                                  ),
                                  NavigationDestination(
                                    icon: Icon(Icons.map_rounded),
                                    label: 'Mapa',
                                  ),
                                  NavigationDestination(
                                    icon: Icon(Icons.person_rounded),
                                    label: 'Cuenta',
                                  ),
                                ],
                              ),
                              body: Column(
                                children: [
                                  ShellHeader(
                                    controller: widget.controller,
                                    onNotificationsTap: () =>
                                        _openNotificationsCenter(
                                          context,
                                          widget.controller,
                                        ),
                                    onCartTap: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => CartScreen(
                                          controller: widget.controller,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: IndexedStack(
                                      index: widget.controller.selectedTabIndex,
                                      children: [
                                        HomeView(
                                          controller: widget.controller,
                                          onOpenRestaurant: (restaurant) =>
                                              _openRestaurant(context, restaurant),
                                          onOpenPost: (post) =>
                                              _openAuthorProfile(context, post),
                                        ),
                                        RestaurantsView(
                                          controller: widget.controller,
                                          onOpenRestaurant: (restaurant) =>
                                              _openRestaurant(context, restaurant),
                                        ),
                                        SocialView(
                                          controller: widget.controller,
                                          onOpenRestaurant: (restaurant) =>
                                              _openRestaurant(context, restaurant),
                                          onOpenPost: (post) =>
                                              _openAuthorProfile(context, post),
                                        ),
                                        MapView(
                                          controller: widget.controller,
                                          onOpenRestaurant: (restaurant) =>
                                              _openRestaurant(context, restaurant),
                                        ),
                                        ProfileView(
                                          controller: widget.controller,
                                          onOpenRestaurant: (restaurant) =>
                                              _openRestaurant(context, restaurant),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            NotificationOverlay(controller: widget.controller),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openRestaurant(BuildContext context, Restaurant restaurant) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RestaurantDetailScreen(
          controller: widget.controller,
          restaurant: restaurant,
        ),
      ),
    );
  }

  void _openAuthorProfile(BuildContext context, FoodPost post) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AuthorProfileScreen(
          controller: widget.controller,
          authorName: post.author,
          authorRole: post.authorRole,
          onOpenRestaurant: (restaurant) => _openRestaurant(context, restaurant),
        ),
      ),
    );
  }
}

class LaCartaBannerCard extends StatelessWidget {
  const LaCartaBannerCard({
    super.key,
    required this.height,
    this.compact = false,
    this.showTagline = false,
    this.imageAsset = 'images/logoLaCartaAPP.png',
    this.imageWidthFactor,
  });

  final double height;
  final bool compact;
  final bool showTagline;
  final String imageAsset;
  final double? imageWidthFactor;

  @override
  Widget build(BuildContext context) {
    final effectiveWidthFactor = imageWidthFactor ?? (compact ? 0.34 : 0.52);

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 26 : 32),
        gradient: const LinearGradient(
          colors: [_brandRedDark, _brandRed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _brandRed.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 26 : 32),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 14 : 18,
                compact ? 12 : 16,
                compact ? 14 : 18,
                showTagline ? 12 : (compact ? 12 : 16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Center(
                      child: FractionallySizedBox(
                        widthFactor: effectiveWidthFactor,
                        child: Image.asset(
                          imageAsset,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                        ),
                      ),
                    ),
                  ),
                  if (showTagline) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Text(
                        'Perfil social, pedidos y restaurantes guardados en una sola experiencia.',
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: compact ? 10 : 11,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LaCartaLogoMark extends StatelessWidget {
  const LaCartaLogoMark({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'images/logoLaCartaAPP.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class ShellHeader extends StatelessWidget {
  const ShellHeader({
    super.key,
    required this.controller,
    required this.onNotificationsTap,
    required this.onCartTap,
  });

  final AppController controller;
  final VoidCallback onNotificationsTap;
  final VoidCallback onCartTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: const BoxDecoration(color: _surface),
      child: Column(
        children: [
          const LaCartaBannerCard(
            height: 96,
            compact: true,
            imageAsset: 'images/logo_la_carta-01.png',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SearchField(
                  initialValue: controller.searchQuery,
                  hintText: 'Buscar platos o restaurantes',
                  onChanged: controller.updateSearch,
                ),
              ),
              const SizedBox(width: 10),
              _HeaderActionButton(
                onPressed: onNotificationsTap,
                count: controller.unreadNotificationsCount,
                icon: Icons.notifications_rounded,
                semanticLabel: 'Notificaciones',
              ),
              const SizedBox(width: 10),
              _HeaderActionButton(
                onPressed: onCartTap,
                count: controller.cartCount,
                icon: Icons.shopping_bag_rounded,
                semanticLabel: 'Carrito',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.onPressed,
    required this.count,
    required this.icon,
    required this.semanticLabel,
  });

  final VoidCallback onPressed;
  final int count;
  final IconData icon;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: IconButton.filledTonal(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: _canvas,
          foregroundColor: _coral,
          minimumSize: const Size(50, 50),
        ),
        icon: Badge(
          isLabelVisible: count > 0,
          label: Text(count.toString()),
          child: Icon(icon),
        ),
      ),
    );
  }
}

class HomeLocationCard extends StatelessWidget {
  const HomeLocationCard({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 380;
            return compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: _coral.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.near_me_rounded, color: _coral),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tu ubicación actual',
                                  style: GoogleFonts.manrope(
                                    color: _muted,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  controller.deliveryAddress,
                                  style: GoogleFonts.sora(
                                    color: _ink,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      FilledButton.tonalIcon(
                        onPressed: () {},
                        icon: const Icon(Icons.edit_location_alt_rounded),
                        label: const Text('Editar'),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: _coral.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.near_me_rounded, color: _coral),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tu ubicación actual',
                              style: GoogleFonts.manrope(
                                color: _muted,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              controller.deliveryAddress,
                              style: GoogleFonts.sora(
                                color: _ink,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () {},
                        icon: const Icon(Icons.edit_location_alt_rounded),
                        label: const Text('Editar'),
                      ),
                    ],
                  );
          },
        ),
      ),
    );
  }
}

class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 156,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: _brandRed.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Image.asset(
          'images/bannernoticias.jpg',
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
    );
  }
}

class ProfileHeroCard extends StatelessWidget {
  const ProfileHeroCard({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final initials = _initialsFromName(controller.currentUserName);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _ProfileAvatar(
              imageBytes: controller.currentUserProfileImageBytes,
              initials: initials,
              radius: 42,
            ),
            const SizedBox(height: 14),
            Text(
              controller.currentUserName,
              textAlign: TextAlign.center,
              style: GoogleFonts.sora(
                color: _ink,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              controller.currentUserEmail.isEmpty
                  ? controller.currentUserHandle
                  : controller.currentUserEmail,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                color: _muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileMetricPill extends StatelessWidget {
  const ProfileMetricPill({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFCF8), Color(0xFFF6EDE2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _coral.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: _coral),
              ),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sora(
                      color: _ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      color: _muted,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.imageBytes,
    required this.initials,
    required this.radius,
  });

  final Uint8List? imageBytes;
  final String initials;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius + 4,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: _brandRedDark,
        backgroundImage: imageBytes == null ? null : MemoryImage(imageBytes!),
        child: imageBytes == null
            ? Text(
                initials,
                style: GoogleFonts.sora(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: radius * 0.62,
                ),
              )
            : null,
      ),
    );
  }
}

class RestaurantDetailStatTile extends StatelessWidget {
  const RestaurantDetailStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFCF8), Color(0xFFF6EDE2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _coral.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 20, color: _coral),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.sora(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: _muted,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AccountSectionCard extends StatelessWidget {
  const AccountSectionCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}

class _AccountTag extends StatelessWidget {
  const _AccountTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _coral),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                color: _ink,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AccountAddressTile extends StatelessWidget {
  const AccountAddressTile({super.key, required this.address});

  final SavedAddress address;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: address.isPrimary
                      ? _coral.withValues(alpha: 0.12)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  address.label,
                  style: GoogleFonts.manrope(
                    color: address.isPrimary ? _coral : _ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              if (address.isPrimary) ...[
                const SizedBox(width: 8),
                Text(
                  'Principal',
                  style: GoogleFonts.manrope(
                    color: _muted,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            address.address,
            style: GoogleFonts.sora(
              color: _ink,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          if (address.details.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              address.details,
              style: GoogleFonts.manrope(
                color: _muted,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AccountDishTile extends StatelessWidget {
  const AccountDishTile({
    super.key,
    required this.dish,
    required this.onTap,
  });

  final RecommendedDish dish;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _line),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                dish.imageAsset,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dish.dishName,
                    style: GoogleFonts.sora(
                      color: _ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dish.restaurantName,
                    style: GoogleFonts.manrope(
                      color: _muted,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dish.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      color: _muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _currency(dish.price),
              style: GoogleFonts.sora(
                color: _coral,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DeliveryMapCard extends StatelessWidget {
  const DeliveryMapCard({super.key, required this.snapshot});

  final DeliveryMapSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFF151515), Color(0xFF2B2B2B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _gold,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.map_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        snapshot.title,
                        style: GoogleFonts.sora(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${snapshot.status} · ${snapshot.eta}',
                        style: GoogleFonts.manrope(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  snapshot.courierName,
                  style: GoogleFonts.manrope(
                    color: _gold,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _RoutePainter(progress: snapshot.progress),
                    ),
                  ),
                  Positioned(
                    left: 22,
                    top: 24,
                    child: _MapPoint(label: 'Pickup', color: _gold),
                  ),
                  Positioned(
                    right: 24,
                    bottom: 22,
                    child: _MapPoint(label: 'Destino', color: _coral),
                  ),
                  Positioned(
                    left: 110 + (snapshot.progress * 90),
                    top: 50 + (snapshot.progress * 18),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.delivery_dining_rounded,
                        color: _coral,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    snapshot.pickupLabel,
                    style: GoogleFonts.manrope(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    snapshot.dropoffLabel,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.manrope(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPoint extends StatelessWidget {
  const _MapPoint({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final activePaint = Paint()
      ..color = _gold
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = ui.Path()
      ..moveTo(36, 42)
      ..quadraticBezierTo(
        size.width * 0.35,
        18,
        size.width * 0.52,
        size.height * 0.45,
      )
      ..quadraticBezierTo(
        size.width * 0.66,
        size.height * 0.82,
        size.width - 36,
        size.height - 34,
      );

    canvas.drawPath(path, basePaint);

    final metrics = path.computeMetrics().first;
    final activePath = metrics.extractPath(
      0,
      metrics.length * progress.clamp(0, 1),
    );
    canvas.drawPath(activePath, activePaint);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class SocialClipCard extends StatelessWidget {
  const SocialClipCard({super.key, required this.clip, required this.onTap});

  final SocialClip clip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Positioned.fill(
                child: clip.mediaBytes != null
                    ? Image.memory(clip.mediaBytes!, fit: BoxFit.cover)
                    : Image.asset(clip.coverImage, fit: BoxFit.cover),
              ),
              Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.68),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          Text(
                            clip.durationLabel,
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      clip.viewsLabel,
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  clip.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.sora(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  clip.mediaLabel == null
                      ? clip.author
                      : '${clip.author} · ${clip.mediaLabel}',
                  style: GoogleFonts.manrope(
                    color: Colors.white.withValues(alpha: 0.84),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FoodPostCard extends StatelessWidget {
  const FoodPostCard({
    super.key,
    required this.post,
    this.onOpenPost,
    required this.onLike,
    required this.onComment,
    this.onOpenRestaurant,
    this.showCommentAction = true,
    this.headerTitle,
    this.headerSubtitle,
  });

  final FoodPost post;
  final VoidCallback? onOpenPost;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback? onOpenRestaurant;
  final bool showCommentAction;
  final String? headerTitle;
  final String? headerSubtitle;

  @override
  Widget build(BuildContext context) {
    final effectiveTitle = headerTitle ?? post.author;
    final effectiveSubtitle =
        headerSubtitle ?? '${post.restaurantName} · ${post.authorRole}';

    return InkWell(
      onTap: onOpenPost,
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _surface,
                    backgroundImage: AssetImage(
                      restaurants
                          .firstWhere((r) => r.id == post.restaurantId)
                          .logoAsset,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          effectiveTitle,
                          style: GoogleFonts.sora(
                            fontWeight: FontWeight.w800,
                            color: _ink,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          effectiveSubtitle,
                          style: GoogleFonts.manrope(
                            color: _muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.more_horiz_rounded, color: _muted),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: post.mediaBytes != null
                    ? Image.memory(
                        post.mediaBytes!,
                        height: 230,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        post.imageAsset,
                        height: 230,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: onLike,
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                post.likedByCurrentUser
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color:
                                    post.likedByCurrentUser ? _coral : _muted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                post.likesLabel,
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w800,
                                  color: _ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (showCommentAction) ...[
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: onComment,
                          borderRadius: BorderRadius.circular(999),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.mode_comment_outlined,
                                  color: _muted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  post.commentsLabel,
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w800,
                                    color: _ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: _line),
                          ),
                          child: Text(
                            'Recomendado',
                            style: GoogleFonts.manrope(
                              color: _coral,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    post.caption,
                    style: GoogleFonts.manrope(
                      color: _ink,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (post.mediaLabel != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Archivo: ${post.mediaLabel}',
                      style: GoogleFonts.manrope(
                        color: _muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: post.tags
                        .map(
                          (tag) => Chip(
                            label: Text('#$tag'),
                            backgroundColor: _surface,
                            side: const BorderSide(color: _line),
                          ),
                        )
                        .toList(),
                  ),
                  if (onOpenRestaurant != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: onOpenRestaurant,
                      icon: const Icon(Icons.storefront_rounded),
                      label: const Text('Ver restaurante'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserDishRecommendationCard extends StatelessWidget {
  const UserDishRecommendationCard({
    super.key,
    required this.post,
    required this.onLike,
    this.onOpenRestaurant,
  });

  final FoodPost post;
  final VoidCallback onLike;
  final VoidCallback? onOpenRestaurant;

  @override
  Widget build(BuildContext context) {
    final dishName = post.featuredDishName ?? 'Platillo recomendado';

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _coral.withValues(alpha: 0.10),
                  backgroundImage: post.authorImageBytes == null
                      ? null
                      : MemoryImage(post.authorImageBytes!),
                  child: post.authorImageBytes == null
                      ? Text(
                          post.author.substring(0, 1).toUpperCase(),
                          style: GoogleFonts.sora(
                            color: _coral,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author,
                        style: GoogleFonts.sora(
                          fontWeight: FontWeight.w800,
                          color: _ink,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Recomendó $dishName en ${post.restaurantName}',
                        style: GoogleFonts.manrope(
                          color: _muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _line),
                  ),
                  child: Text(
                    'Verificada',
                    style: GoogleFonts.manrope(
                      color: _coral,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: post.mediaBytes != null
                  ? Image.memory(
                      post.mediaBytes!,
                      height: 230,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      post.imageAsset,
                      height: 230,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        dishName,
                        style: GoogleFonts.sora(
                          color: _ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onLike,
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              post.likedByCurrentUser
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: post.likedByCurrentUser ? _coral : _muted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              post.likesLabel,
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  post.restaurantName,
                  style: GoogleFonts.manrope(
                    color: _coral,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (post.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: post.tags
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                            backgroundColor: _surface,
                            side: const BorderSide(color: _line),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (onOpenRestaurant != null) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: onOpenRestaurant,
                    icon: const Icon(Icons.storefront_rounded),
                    label: const Text('Ver restaurante'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FoodPostDetailScreen extends StatefulWidget {
  const FoodPostDetailScreen({
    super.key,
    required this.controller,
    required this.post,
    required this.onOpenRestaurant,
  });

  final AppController controller;
  final FoodPost post;
  final ValueChanged<Restaurant> onOpenRestaurant;

  @override
  State<FoodPostDetailScreen> createState() => _FoodPostDetailScreenState();
}

class _FoodPostDetailScreenState extends State<FoodPostDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final post = widget.controller.filteredFoodPosts.firstWhere(
          (entry) => entry.id == widget.post.id,
          orElse: () => widget.post,
        );
        final restaurant = widget.controller.restaurantById(post.restaurantId);
        final comments = post.isVerifiedOrder
            ? const <RestaurantComment>[]
            : widget.controller.commentsForRestaurant(post.restaurantId);

        return Scaffold(
          backgroundColor: _canvas,
          appBar: AppBar(title: const Text('Recomendacion')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              post.isVerifiedOrder
                  ? UserDishRecommendationCard(
                      post: post,
                      onLike: () => widget.controller.toggleFoodPostLike(post.id),
                      onOpenRestaurant: () {
                        if (restaurant != null) {
                          widget.onOpenRestaurant(restaurant);
                        }
                      },
                    )
                  : FoodPostCard(
                      post: post,
                      onOpenPost: () {},
                      onLike: () => widget.controller.toggleFoodPostLike(post.id),
                      onComment: () {},
                      showCommentAction: false,
                      onOpenRestaurant: () {
                        if (restaurant != null) {
                          widget.onOpenRestaurant(restaurant);
                        }
                      },
                    ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.isVerifiedOrder
                            ? 'Recomendación del usuario'
                            : 'Recomendacion verificada',
                        style: GoogleFonts.sora(
                          color: _ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        post.isVerifiedOrder
                            ? 'Esta recomendación solo acepta corazones. No muestra comentarios ni permite entrar a perfiles de usuarios.'
                            : 'Esta publicacion solo acepta corazones. Si el pedido no fue recomendable, el feedback se envia de forma privada al restaurante.',
                        style: GoogleFonts.manrope(
                          color: _muted,
                          fontWeight: FontWeight.w700,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (comments.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '${comments.length} comentario${comments.length == 1 ? '' : 's'} historico${comments.length == 1 ? '' : 's'} asociado${comments.length == 1 ? '' : 's'} al restaurante.',
                      style: GoogleFonts.manrope(
                        color: _muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class AuthorProfileScreen extends StatelessWidget {
  const AuthorProfileScreen({
    super.key,
    required this.controller,
    required this.authorName,
    required this.authorRole,
    required this.onOpenRestaurant,
  });

  final AppController controller;
  final String authorName;
  final String authorRole;
  final ValueChanged<Restaurant> onOpenRestaurant;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final posts = controller.postsByAuthor(authorName);
        final clips = controller.clipsByAuthor(authorName);

        return Scaffold(
          backgroundColor: _canvas,
          appBar: AppBar(title: const Text('Perfil del creador')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: _canvas,
                        child: Text(
                          authorName.substring(0, 1).toUpperCase(),
                          style: GoogleFonts.sora(
                            color: _coral,
                            fontWeight: FontWeight.w800,
                            fontSize: 26,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        authorName,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.sora(
                          color: _ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authorRole,
                        style: GoogleFonts.manrope(
                          color: _muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ProfileMetricPill(
                              label: 'Posts',
                              value: '${posts.length}',
                              icon: Icons.grid_view_rounded,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ProfileMetricPill(
                              label: 'Reels',
                              value: '${clips.length}',
                              icon: Icons.play_circle_fill_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (clips.isNotEmpty) ...[
                const SizedBox(height: 20),
                const SectionTitle(eyebrow: 'Reels', title: 'Contenido en video'),
                const SizedBox(height: 14),
                SizedBox(
                  height: 220,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: clips.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final clip = clips[index];
                      return SocialClipCard(
                        clip: clip,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => SocialReelViewerScreen(
                                controller: controller,
                                clipIds: clips.map((entry) => entry.id).toList(),
                                initialIndex: index,
                                onOpenRestaurant: onOpenRestaurant,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const SectionTitle(eyebrow: 'Posts', title: 'Publicaciones del creador'),
              const SizedBox(height: 14),
              if (posts.isEmpty)
                const EmptyState(
                  icon: Icons.feed_outlined,
                  title: 'Sin publicaciones',
                  message: 'Este perfil aún no tiene posts visibles.',
                )
              else
                ...posts.map(
                  (post) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: FoodPostCard(
                      post: post,
                      onOpenPost: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => FoodPostDetailScreen(
                              controller: controller,
                              post: post,
                              onOpenRestaurant: onOpenRestaurant,
                            ),
                          ),
                        );
                      },
                      onLike: () => controller.toggleFoodPostLike(post.id),
                      onComment: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => FoodPostDetailScreen(
                              controller: controller,
                              post: post,
                              onOpenRestaurant: onOpenRestaurant,
                            ),
                          ),
                        );
                      },
                      onOpenRestaurant: () {
                        final restaurant = controller.restaurantById(post.restaurantId);
                        if (restaurant != null) {
                          onOpenRestaurant(restaurant);
                        }
                      },
                      showCommentAction: false,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class SocialReelViewerScreen extends StatefulWidget {
  const SocialReelViewerScreen({
    super.key,
    required this.controller,
    required this.clipIds,
    this.initialIndex = 0,
    this.onOpenRestaurant,
  });

  final AppController controller;
  final List<String> clipIds;
  final int initialIndex;
  final ValueChanged<Restaurant>? onOpenRestaurant;

  @override
  State<SocialReelViewerScreen> createState() => _SocialReelViewerScreenState();
}

class _SocialReelViewerScreenState extends State<SocialReelViewerScreen> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final clips = widget.clipIds
            .map(widget.controller.clipById)
            .whereType<SocialClip>()
            .toList();

        if (clips.isEmpty) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Center(
                child: EmptyState(
                  icon: Icons.play_circle_outline_rounded,
                  title: 'Sin reels',
                  message: 'No hay reels disponibles para mostrar.',
                ),
              ),
            ),
          );
        }

        final safeIndex = _currentIndex.clamp(0, clips.length - 1);

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: clips.length,
                onPageChanged: (value) {
                  setState(() {
                    _currentIndex = value;
                  });
                },
                itemBuilder: (context, index) {
                  final clip = clips[index];
                  final restaurant = widget.controller.restaurantById(clip.restaurantId);
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      clip.mediaBytes != null
                          ? Image.memory(clip.mediaBytes!, fit: BoxFit.cover)
                          : Image.asset(clip.coverImage, fit: BoxFit.cover),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.20),
                              Colors.black.withValues(alpha: 0.05),
                              Colors.black.withValues(alpha: 0.82),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  IconButton.filledTonal(
                                    onPressed: () => Navigator.of(context).pop(),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.black.withValues(alpha: 0.30),
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.arrow_back_rounded),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          clip.author,
                                          style: GoogleFonts.sora(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 22,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          clip.title,
                                          style: GoogleFonts.manrope(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            height: 1.4,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          restaurant == null
                                              ? clip.viewsLabel
                                              : '${restaurant.name} · ${clip.viewsLabel}',
                                          style: GoogleFonts.manrope(
                                            color: Colors.white.withValues(alpha: 0.82),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _ReelActionButton(
                                        icon: clip.likedByCurrentUser
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        label: clip.likesLabel,
                                        active: clip.likedByCurrentUser,
                                        onTap: () => widget.controller.toggleSocialClipLike(clip.id),
                                      ),
                                      const SizedBox(height: 16),
                                      _ReelActionButton(
                                        icon: Icons.mode_comment_outlined,
                                        label: clip.commentsLabel,
                                        onTap: () => _showReelCommentsSheet(context, widget.controller, clip),
                                      ),
                                      const SizedBox(height: 16),
                                      _ReelActionButton(
                                        icon: Icons.share_rounded,
                                        label: 'Compartir',
                                        onTap: () async {
                                          await Clipboard.setData(
                                            ClipboardData(
                                              text: 'La Carta · ${clip.author} · ${clip.title}',
                                            ),
                                          );
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Texto del reel copiado para compartir.'),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      if (restaurant != null && widget.onOpenRestaurant != null) ...[
                                        const SizedBox(height: 16),
                                        _ReelActionButton(
                                          icon: Icons.storefront_rounded,
                                          label: 'Restaurante',
                                          onTap: () => widget.onOpenRestaurant!(restaurant),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              IgnorePointer(
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: LinearProgressIndicator(
                    value: (safeIndex + 1) / clips.length,
                    minHeight: 2,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    valueColor: const AlwaysStoppedAnimation<Color>(_coral),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReelActionButton extends StatelessWidget {
  const _ReelActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.black.withValues(alpha: 0.30),
            child: Icon(
              icon,
              color: active ? _coral : Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showReelCommentsSheet(
  BuildContext context,
  AppController controller,
  SocialClip clip,
) async {
  final commentController = TextEditingController();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final comments = controller.commentsForRestaurant(clip.restaurantId);

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              top: 24,
            ),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 52,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _line,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Comentarios del reel',
                    style: GoogleFonts.sora(
                      color: _ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: commentController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: _inputDecoration(
                      'Escribe tu comentario',
                      Icons.mode_comment_outlined,
                    ),
                    style: GoogleFonts.manrope(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: () {
                        controller.addRestaurantComment(
                          restaurantId: clip.restaurantId,
                          message: commentController.text,
                        );
                        commentController.clear();
                      },
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Comentar'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: comments.isEmpty
                        ? const EmptyState(
                            icon: Icons.chat_bubble_outline_rounded,
                            title: 'Sin comentarios',
                            message: 'Sé el primero en comentar este reel.',
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: comments.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              return RestaurantCommentCard(
                                comment: comment,
                                onLike: () => controller.toggleCommentLike(
                                  restaurantId: clip.restaurantId,
                                  commentId: comment.id,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  commentController.dispose();
}

class PaymentMethodTile extends StatelessWidget {
  const PaymentMethodTile({
    super.key,
    required this.method,
    required this.selectedType,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethodOption method;
  final PaymentMethodType selectedType;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? _coral.withValues(alpha: 0.08) : _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _coral : _line),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: selected ? _coral : Colors.white,
              foregroundColor: selected ? Colors.white : _ink,
              child: Icon(_paymentMethodIcon(method.type)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.label,
                    style: GoogleFonts.sora(
                      fontWeight: FontWeight.w800,
                      color: _ink,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    method.subtitle,
                    style: GoogleFonts.manrope(
                      color: _muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? _coral : _muted, width: 2),
                color: selected ? _coral : Colors.transparent,
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({
    super.key,
    required this.controller,
    required this.onOpenRestaurant,
    required this.onOpenPost,
  });

  final AppController controller;
  final ValueChanged<Restaurant> onOpenRestaurant;
  final ValueChanged<FoodPost> onOpenPost;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        const HomeHeroCard(),
        const SizedBox(height: 24),
        const SectionTitle(eyebrow: 'Promos', title: 'Campañas activas'),
        const SizedBox(height: 14),
        PromoCarousel(
          promotions: controller.filteredPromotions,
          onTap: (promo) {
            final restaurant = controller.restaurantById(promo.restaurantId);
            if (restaurant != null) {
              onOpenRestaurant(restaurant);
            }
          },
        ),
        const SizedBox(height: 24),
        const SectionTitle(
          eyebrow: 'Top del día',
          title: 'Los mejores restaurantes de hoy',
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 230,
          child: controller.recommendedRestaurants.isEmpty
              ? const EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Sin coincidencias',
                  message: 'Prueba otra búsqueda o cambia la categoría activa.',
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.recommendedRestaurants.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final restaurant = controller.recommendedRestaurants[index];
                    return FeaturedRestaurantCard(
                      restaurant: restaurant,
                      onTap: () => onOpenRestaurant(restaurant),
                    );
                  },
                ),
        ),
        const SizedBox(height: 24),
        const SectionTitle(
          eyebrow: 'Recomendados',
          title: 'Los mejores platos que te pueden llenar',
        ),
        const SizedBox(height: 14),
        ...controller.homeDishFeed.map(
          (dish) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: RecommendedDishCard(
              dish: dish,
              liked: controller.likedRecommendedDishes.contains(dish.dishName),
              onTap: () {
                final restaurant = controller.restaurantById(dish.restaurantId);
                if (restaurant != null) {
                  onOpenRestaurant(restaurant);
                }
              },
              onAdd: () => controller.addRecommendedDish(dish),
              onLike: () => controller.likeRecommendedDish(dish),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const SectionTitle(
          eyebrow: 'Social food',
          title: 'Los post más deliciosos',
        ),
        const SizedBox(height: 14),
        ...controller.homeSocialFeed.map(
          (post) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: FoodPostCard(
              post: post,
              onOpenPost: () {
                final restaurant = controller.restaurantById(post.restaurantId);
                if (restaurant != null) {
                  onOpenRestaurant(restaurant);
                }
              },
              onLike: () => controller.toggleFoodPostLike(post.id),
              onComment: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => FoodPostDetailScreen(
                      controller: controller,
                      post: post,
                      onOpenRestaurant: onOpenRestaurant,
                    ),
                  ),
                );
              },
              showCommentAction: false,
              headerTitle: post.restaurantName,
              headerSubtitle: 'Delicia recomendada del restaurante',
              onOpenRestaurant: () {
                final restaurant = controller.restaurantById(post.restaurantId);
                if (restaurant != null) {
                  onOpenRestaurant(restaurant);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _HotBadge extends StatelessWidget {
  const _HotBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0E5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: Color(0xFFF06A23),
            size: 15,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.manrope(
              color: const Color(0xFFF06A23),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class SocialComposerCard extends StatelessWidget {
  const SocialComposerCard({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final pendingRecommendations = controller.pendingRecommendationCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recomienda desde tu pedido',
              style: GoogleFonts.sora(
                color: _ink,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Las recomendaciones nacen de pedidos entregados. Si la experiencia fue buena, pasa al feed como recomendacion verificada y otros usuarios solo pueden darle corazon.',
              style: GoogleFonts.manrope(
                color: _muted,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _line),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _coral.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.thumb_up_alt_rounded,
                      color: _coral,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pendingRecommendations > 0
                              ? 'Tienes $pendingRecommendations pedido${pendingRecommendations == 1 ? '' : 's'} listo${pendingRecommendations == 1 ? '' : 's'} para recomendar'
                              : 'Cuando completes un pedido podras decidir si lo recomiendas o no',
                          style: GoogleFonts.sora(
                            color: _ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hazlo desde Historial de pedidos para convertirlo en una recomendacion visible dentro de Social.',
                          style: GoogleFonts.manrope(
                            color: _muted,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SocialView extends StatelessWidget {
  const SocialView({
    super.key,
    required this.controller,
    required this.onOpenRestaurant,
    required this.onOpenPost,
  });

  final AppController controller;
  final ValueChanged<Restaurant> onOpenRestaurant;
  final ValueChanged<FoodPost> onOpenPost;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        const SectionTitle(
          eyebrow: 'Restaurantes',
          title: 'Las delicias recomendadas de los restaurantes',
        ),
        const SizedBox(height: 14),
        if (controller.restaurantSocialPosts.isEmpty)
          const EmptyState(
            icon: Icons.storefront_outlined,
            title: 'Sin delicias visibles',
            message:
                'Cuando un restaurante publique una delicia, aparecera aqui.',
          )
        else
          ...controller.restaurantSocialPosts.map(
            (post) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FoodPostCard(
                post: post,
                onOpenPost: () {
                  final restaurant = controller.restaurantById(post.restaurantId);
                  if (restaurant != null) {
                    onOpenRestaurant(restaurant);
                  }
                },
                onLike: () => controller.toggleFoodPostLike(post.id),
                onComment: () {},
                showCommentAction: false,
                headerTitle: post.restaurantName,
                headerSubtitle: 'Delicia recomendada del restaurante',
                onOpenRestaurant: () {
                  final restaurant = controller.restaurantById(
                    post.restaurantId,
                  );
                  if (restaurant != null) {
                    onOpenRestaurant(restaurant);
                  }
                },
              ),
            ),
          ),
        const SizedBox(height: 24),
        const SectionTitle(
          eyebrow: 'Usuarios',
          title: 'Los platillos recomendados por usuarios',
        ),
        const SizedBox(height: 14),
        if (controller.userRecommendedDishPosts.isEmpty)
          const EmptyState(
            icon: Icons.thumb_up_alt_outlined,
            title: 'Sin recomendaciones de usuarios',
            message:
                'Cuando un pedido entregado se recomiende con buena vibra, aparecera aqui.',
          )
        else
          ...controller.userRecommendedDishPosts.map(
            (post) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: UserDishRecommendationCard(
                post: post,
                onLike: () => controller.toggleFoodPostLike(post.id),
                onOpenRestaurant: () {
                  final restaurant = controller.restaurantById(post.restaurantId);
                  if (restaurant != null) {
                    onOpenRestaurant(restaurant);
                  }
                },
              ),
            ),
          ),
      ],
    );
  }
}

class MapView extends StatefulWidget {
  const MapView({
    super.key,
    required this.controller,
    required this.onOpenRestaurant,
  });

  final AppController controller;
  final ValueChanged<Restaurant> onOpenRestaurant;

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  late final TextEditingController _searchController;
  final GlobalKey<_RestaurantMapExplorerState> _mapExplorerKey =
      GlobalKey<_RestaurantMapExplorerState>();
  Restaurant? _selectedRestaurant;
  Position? _userPosition;
  String _mapQuery = '';
  bool _hasHandledInitialLocationRequest = false;
  bool _isLocatingUser = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedRestaurant = null;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Restaurant> get _filteredRestaurants {
    final query = _mapQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return restaurants;
    }

    return restaurants.where((restaurant) {
      return restaurant.name.toLowerCase().contains(query) ||
          restaurant.address.toLowerCase().contains(query) ||
          restaurant.description.toLowerCase().contains(query) ||
          restaurant.tags.any((tag) => tag.toLowerCase().contains(query));
    }).toList();
  }

  void _handleSearchChanged(String value) {
    setState(() {
      _mapQuery = value;
      final matches = _filteredRestaurants;
      if (matches.isEmpty) {
        _selectedRestaurant = null;
      } else if (_selectedRestaurant == null ||
          !matches.any((restaurant) => restaurant.id == _selectedRestaurant!.id)) {
        _selectedRestaurant = matches.first;
      }
    });
  }

  void _focusOnFirstSearchMatch(String _) {
    final matches = _filteredRestaurants;
    if (matches.isEmpty) {
      _showMapSnackBar('No encontramos ese restaurante en el mapa.');
      return;
    }

    setState(() {
      _selectedRestaurant = matches.first;
    });
  }

  void _maybeRequestLocationAccess() {
    if (_hasHandledInitialLocationRequest || widget.controller.selectedTabIndex != 3) {
      return;
    }

    _hasHandledInitialLocationRequest = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _requestLocationAndMaybeCenter();
    });
  }

  Future<void> _requestLocationAndMaybeCenter() async {
    if (_isLocatingUser) {
      return;
    }

    setState(() {
      _isLocatingUser = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMapSnackBar('Activa la ubicación del dispositivo para usar esta función.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMapSnackBar('No se concedió permiso de ubicación.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _userPosition = position;
      });

      _mapExplorerKey.currentState?.focusOnCoordinates(
        LatLng(position.latitude, position.longitude),
        zoom: 15.6,
      );
    } catch (_) {
      _showMapSnackBar('No se pudo obtener tu ubicación actual.');
    } finally {
      if (mounted) {
        setState(() {
          _isLocatingUser = false;
        });
      }
    }
  }

  void _resetMapView() {
    _searchController.clear();
    setState(() {
      _mapQuery = '';
      _selectedRestaurant = null;
    });
    _mapExplorerKey.currentState?.resetToPasto();
  }

  void _clearSelection() {
    setState(() {
      _selectedRestaurant = null;
    });
    _mapExplorerKey.currentState?.resetToPasto();
  }

  void _showMapSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    _maybeRequestLocationAccess();
    final filteredRestaurants = _filteredRestaurants;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
      child: Column(
        children: [
          SearchField(
            controller: _searchController,
            hintText: 'Buscar restaurante en el mapa',
            onChanged: _handleSearchChanged,
            onSubmitted: _focusOnFirstSearchMatch,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: RestaurantMapExplorer(
                    key: _mapExplorerKey,
                    restaurants: filteredRestaurants,
                    selectedRestaurant: _selectedRestaurant,
                    userLocation: _userPosition == null
                        ? null
                        : LatLng(
                            _userPosition!.latitude,
                            _userPosition!.longitude,
                          ),
                    onSelectRestaurant: (restaurant) {
                      setState(() {
                        _selectedRestaurant = restaurant;
                      });
                    },
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Column(
                    children: [
                      _MapFloatingActionButton(
                        icon: _isLocatingUser
                            ? Icons.hourglass_top_rounded
                            : Icons.my_location_rounded,
                        tooltip: 'Tu ubicación',
                        onTap: _isLocatingUser
                            ? null
                            : _requestLocationAndMaybeCenter,
                      ),
                      const SizedBox(height: 10),
                      _MapFloatingActionButton(
                        icon: Icons.center_focus_strong_rounded,
                        tooltip: 'Ver todo',
                        onTap: _resetMapView,
                      ),
                      if (_selectedRestaurant != null) ...[
                        const SizedBox(height: 10),
                        _MapFloatingActionButton(
                          icon: Icons.close_rounded,
                          tooltip: 'Quitar selección',
                          onTap: _clearSelection,
                        ),
                      ],
                    ],
                  ),
                ),
                if (_mapQuery.isNotEmpty && filteredRestaurants.isEmpty)
                  const Positioned(
                    top: 16,
                    left: 16,
                    right: 84,
                    child: _MapStatusPill(
                      message: 'No encontramos ese restaurante en el mapa.',
                    ),
                  ),
              ],
            ),
          ),
          if (_selectedRestaurant != null) ...[
            const SizedBox(height: 14),
            MapRestaurantCard(
              restaurant: _selectedRestaurant!,
              onTap: () => widget.onOpenRestaurant(_selectedRestaurant!),
              onOpenMaps: () =>
                  _openMapsForRestaurant(context, _selectedRestaurant!),
            ),
          ],
        ],
      ),
    );
  }
}

class _MapFloatingActionButton extends StatelessWidget {
  const _MapFloatingActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _line),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: _ink),
          ),
        ),
      ),
    );
  }
}

class _MapStatusPill extends StatelessWidget {
  const _MapStatusPill({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_off_rounded, color: _coral),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.manrope(
                color: _ink,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RestaurantsView extends StatelessWidget {
  const RestaurantsView({
    super.key,
    required this.controller,
    required this.onOpenRestaurant,
  });

  final AppController controller;
  final ValueChanged<Restaurant> onOpenRestaurant;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        SearchField(
          initialValue: controller.searchQuery,
          hintText: 'Buscar restaurantes o platos',
          onChanged: controller.updateSearch,
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: restaurantFilters.map((filter) {
              final selected = controller.selectedRestaurantFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: selected,
                  label: Text(restaurantFilterLabels[filter] ?? filter),
                  onSelected: (_) => controller.setRestaurantFilter(filter),
                  selectedColor: _coral,
                  backgroundColor: _surface,
                  labelStyle: GoogleFonts.manrope(
                    color: selected ? Colors.white : _ink,
                    fontWeight: FontWeight.w800,
                  ),
                  side: const BorderSide(color: _line),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 18),
        ...controller.filteredRestaurants.map(
          (restaurant) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: RestaurantCard(
              restaurant: restaurant,
              isFavorite: controller.favoriteRestaurantIds.contains(
                restaurant.id,
              ),
              showMetaLine: false,
              onTap: () => onOpenRestaurant(restaurant),
              onFavoriteTap: () =>
                  controller.toggleFavoriteRestaurant(restaurant.id),
            ),
          ),
        ),
        if (controller.filteredRestaurants.isEmpty)
          const EmptyState(
            icon: Icons.storefront_outlined,
            title: 'No encontramos restaurantes',
            message:
                'Cambia el filtro activo o revisa el texto que escribiste.',
          ),
      ],
    );
  }
}

class RewardsView extends StatelessWidget {
  const RewardsView({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        RewardPointsCard(controller: controller),
        const SizedBox(height: 20),
        TriviaCard(controller: controller),
        const SizedBox(height: 24),
        const SectionTitle(
          eyebrow: 'Retos activos',
          title: 'Suma puntos rápido',
        ),
        const SizedBox(height: 12),
        ...controller.challenges.map(
          (challenge) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ChallengeCard(
              challenge: challenge,
              onComplete: challenge.completed
                  ? null
                  : () => controller.completeChallenge(challenge.id),
            ),
          ),
        ),
        const SizedBox(height: 24),
        RewardWheelCard(controller: controller),
        const SizedBox(height: 24),
        const SectionTitle(
          eyebrow: 'Premios desbloqueados',
          title: 'Tu colección',
        ),
        const SizedBox(height: 12),
        if (controller.unlockedRewards.isEmpty)
          const EmptyState(
            icon: Icons.card_giftcard_rounded,
            title: 'Aún no hay premios',
            message:
                'Gira la ruleta o completa retos para empezar a desbloquearlos.',
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: controller.unlockedRewards.map((reward) {
              return Chip(
                avatar: const Icon(
                  Icons.workspace_premium_rounded,
                  color: _coral,
                  size: 18,
                ),
                label: Text(reward),
                backgroundColor: _card,
                side: const BorderSide(color: _line),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class ProfileView extends StatelessWidget {
  const ProfileView({
    super.key,
    required this.controller,
    required this.onOpenRestaurant,
  });

  final AppController controller;
  final ValueChanged<Restaurant> onOpenRestaurant;

  void _openAccountScreen(BuildContext context, Widget child) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeOrdersCount = controller.activeOrders.length;
    final orderHistoryCount = controller.orderHistory.length;
    final reviewedRecommendationsCount = controller.orderHistory
        .where((order) => controller.hasReviewedOrder(order.id))
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        ProfileHeroCard(
          controller: controller,
        ),
        const SizedBox(height: 18),
        AccountSectionCard(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tu cuenta',
                      style: GoogleFonts.sora(
                        color: _ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Administra tus datos, pedidos y recomendaciones desde un solo lugar.',
                      style: GoogleFonts.manrope(
                        color: _muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              _AccountMenuTile(
                icon: Icons.badge_rounded,
                title: 'Mis datos',
                subtitle:
                    'Foto de perfil, nombre, teléfono y mis direcciones.',
                onTap: () => _openAccountScreen(
                  context,
                  AccountPersonalDataScreen(controller: controller),
                ),
              ),
              const _AccountMenuDivider(),
              const _AccountMenuSectionHeader(label: 'Pedidos'),
              _AccountMenuTile(
                icon: Icons.delivery_dining_rounded,
                title: 'Mis pedidos activos',
                subtitle: 'Sigue el estado de lo que está en camino.',
                badge: '$activeOrdersCount',
                onTap: () => _openAccountScreen(
                  context,
                  AccountOrdersScreen(
                    controller: controller,
                    showActiveOrders: true,
                  ),
                ),
              ),
              const _AccountMenuDivider(),
              _AccountMenuTile(
                icon: Icons.receipt_long_rounded,
                title: 'Mi historial de pedidos',
                subtitle: 'Revisa tus pedidos anteriores y vuelve a pedir.',
                badge: '$orderHistoryCount',
                onTap: () => _openAccountScreen(
                  context,
                  AccountOrdersScreen(
                    controller: controller,
                    showActiveOrders: false,
                  ),
                ),
              ),
              const _AccountMenuDivider(),
              _AccountMenuTile(
                icon: Icons.thumb_up_alt_rounded,
                title: 'Mis recomendaciones',
                subtitle:
                    'Mira los pedidos que ya convertiste en recomendación.',
                badge: '$reviewedRecommendationsCount',
                onTap: () => _openAccountScreen(
                  context,
                  AccountRecommendationsScreen(controller: controller),
                ),
              ),
              const _AccountMenuSectionHeader(label: 'Sesión'),
              _AccountMenuTile(
                icon: Icons.logout_rounded,
                title: 'Cerrar sesión',
                subtitle: 'Salir de la cuenta actual en este dispositivo.',
                onTap: () => controller.signOut(),
                isDestructive: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AccountProfileScreen extends StatelessWidget {
  const AccountProfileScreen({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final favoriteRestaurantsCount = controller.favoriteRestaurantIds.length;
    final savedDishesCount = controller.savedDishes.length;
    final addressesCount = controller.profileSavedAddresses.length;

    return _AccountDetailScaffold(
      title: 'Mi perfil',
      subtitle: 'Tu identidad, resumen de actividad y accesos rápidos.',
      children: [
        ProfileHeroCard(
          controller: controller,
        ),
        const SizedBox(height: 18),
        AccountSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Todo tu movimiento dentro de La Carta concentrado en un solo resumen.',
                style: GoogleFonts.manrope(
                  color: _muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 430;
                  final medium = constraints.maxWidth >= 280;
                  final metricWidth = wide
                      ? (constraints.maxWidth - 20) / 3
                      : (medium
                            ? (constraints.maxWidth - 10) / 2
                            : constraints.maxWidth);

                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      SizedBox(
                        width: metricWidth,
                        child: ProfileMetricPill(
                          label: 'Pedidos',
                          value: '${controller.orderHistory.length}',
                          icon: Icons.shopping_bag_rounded,
                        ),
                      ),
                      SizedBox(
                        width: metricWidth,
                        child: ProfileMetricPill(
                          label: 'Posts',
                          value: '${controller.createdPostsCount}',
                          icon: Icons.grid_view_rounded,
                        ),
                      ),
                      SizedBox(
                        width: metricWidth,
                        child: ProfileMetricPill(
                          label: 'Reels',
                          value: '${controller.createdClipsCount}',
                          icon: Icons.play_circle_fill_rounded,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _AccountTag(
                    icon: Icons.favorite_rounded,
                    label: '$favoriteRestaurantsCount restaurantes guardados',
                  ),
                  _AccountTag(
                    icon: Icons.restaurant_menu_rounded,
                    label: '$savedDishesCount platos guardados',
                  ),
                  _AccountTag(
                    icon: Icons.location_city_rounded,
                    label: '$addressesCount direcciones registradas',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AccountPersonalDataScreen extends StatelessWidget {
  const AccountPersonalDataScreen({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final initials = _initialsFromName(controller.currentUserName);
    final addresses = controller.profileSavedAddresses;

    return _AccountDetailScaffold(
      title: 'Mis datos',
      subtitle: 'Foto de perfil, nombre, teléfono y mis direcciones guardadas.',
      children: [
        AccountSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: _ProfileAvatar(
                  imageBytes: controller.currentUserProfileImageBytes,
                  initials: initials,
                  radius: 46,
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => _pickProfileImage(context, controller),
                      icon: const Icon(Icons.photo_camera_rounded),
                      label: const Text('Cambiar foto'),
                    ),
                    if (controller.currentUserProfileImageBytes != null)
                      OutlinedButton.icon(
                        onPressed: () => controller.updateProfileImage(null),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Quitar foto'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Datos de usuario',
                          style: GoogleFonts.sora(
                            color: _ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Aquí puedes cambiar tu nombre, tu teléfono y tu foto de perfil.',
                          style: GoogleFonts.manrope(
                            color: _muted,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonalIcon(
                    onPressed: () => _showPersonalDataSheet(context, controller),
                    icon: const Icon(Icons.edit_note_rounded),
                    label: const Text('Editar todo'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ContactRow(
                icon: Icons.person_outline_rounded,
                text: controller.currentUserName,
              ),
              const SizedBox(height: 8),
              ContactRow(
                icon: Icons.alternate_email_rounded,
                text: controller.currentUserEmail.isEmpty
                    ? 'Sin correo registrado'
                    : controller.currentUserEmail,
              ),
              const SizedBox(height: 8),
              ContactRow(
                icon: Icons.phone_rounded,
                text: controller.currentUserPhone.isEmpty
                    ? 'Agrega un número de contacto'
                    : controller.currentUserPhone,
              ),
              const SizedBox(height: 16),
              Divider(color: _line, height: 24),
              const SizedBox(height: 4),
              Text(
                'Mis direcciones',
                style: GoogleFonts.sora(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Administra casa, trabajo y cualquier otra ubicación guardada desde el mismo editor.',
                style: GoogleFonts.manrope(
                  color: _muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              if (addresses.isEmpty)
                const EmptyState(
                  icon: Icons.location_on_outlined,
                  title: 'Sin direcciones guardadas',
                  message: 'Agrega una dirección para pedir más rápido.',
                )
              else
                ...addresses.map(
                  (address) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AccountAddressTile(address: address),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class AccountAddressesScreen extends StatelessWidget {
  const AccountAddressesScreen({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final addresses = controller.profileSavedAddresses;

    return _AccountDetailScaffold(
      title: 'Direcciones',
      subtitle: 'Guarda varias ubicaciones y define cuál será la principal.',
      children: [
        AccountSectionCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tus direcciones guardadas',
                      style: GoogleFonts.sora(
                        color: _ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Casa, trabajo o cualquier otro punto frecuente para pedir más rápido.',
                      style: GoogleFonts.manrope(
                        color: _muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonalIcon(
                onPressed: () => _showPersonalDataSheet(context, controller),
                icon: const Icon(Icons.edit_location_alt_rounded),
                label: const Text('Editar'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...addresses.map(
          (address) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AccountAddressTile(address: address),
          ),
        ),
      ],
    );
  }
}

class AccountOrdersScreen extends StatelessWidget {
  const AccountOrdersScreen({
    super.key,
    required this.controller,
    required this.showActiveOrders,
  });

  final AppController controller;
  final bool showActiveOrders;

  @override
  Widget build(BuildContext context) {
    final orders = showActiveOrders
        ? controller.activeOrders
        : controller.orderHistory;

    return _AccountDetailScaffold(
      title: showActiveOrders ? 'Pedidos activos' : 'Historial de pedidos',
      subtitle: showActiveOrders
          ? 'Consulta el estado actual de tus órdenes en curso.'
          : 'Revisa tus pedidos anteriores y repítelos en un toque.',
      children: [
        if (orders.isEmpty)
          EmptyState(
            icon: showActiveOrders
                ? Icons.delivery_dining_rounded
                : Icons.receipt_long_rounded,
            title: showActiveOrders
                ? 'Sin pedidos activos'
                : 'Sin pedidos todavía',
            message: showActiveOrders
                ? 'Cuando confirmes un pedido, su estado aparecerá aquí.'
                : 'Cuando confirmes tu primera orden, aparecerá aquí.',
          )
        else
          ...orders.map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AccountOrderCard(
                controller: controller,
                order: order,
                showActiveActions: showActiveOrders,
              ),
            ),
          ),
      ],
    );
  }
}

class AccountRecommendationsScreen extends StatelessWidget {
  const AccountRecommendationsScreen({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final recommendedOrders = controller.orderHistory
        .where((order) => controller.hasReviewedOrder(order.id))
        .toList();

    return _AccountDetailScaffold(
      title: 'Mis recomendaciones',
      subtitle:
          'Estos son los pedidos que ya publicaste como recomendación verificada.',
      children: [
        if (recommendedOrders.isEmpty)
          const EmptyState(
            icon: Icons.thumb_up_alt_outlined,
            title: 'Sin recomendaciones todavía',
            message:
                'Cuando recomiendes un pedido desde tu historial, aparecerá aquí.',
          )
        else
          ...recommendedOrders.map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AccountOrderCard(
                controller: controller,
                order: order,
                showActiveActions: false,
              ),
            ),
          ),
      ],
    );
  }
}

class AccountFavoriteRestaurantsScreen extends StatelessWidget {
  const AccountFavoriteRestaurantsScreen({
    super.key,
    required this.controller,
    required this.onOpenRestaurant,
  });

  final AppController controller;
  final ValueChanged<Restaurant> onOpenRestaurant;

  @override
  Widget build(BuildContext context) {
    final favoriteRestaurants = restaurants
        .where(
          (restaurant) =>
              controller.favoriteRestaurantIds.contains(restaurant.id),
        )
        .toList();

    return _AccountDetailScaffold(
      title: 'Restaurantes guardados',
      subtitle: 'Tus favoritos para volver a pedir sin buscarlos otra vez.',
      children: [
        if (favoriteRestaurants.isEmpty)
          const EmptyState(
            icon: Icons.favorite_border_rounded,
            title: 'No hay favoritos',
            message:
                'Marca restaurantes para llenar esta sección de guardados.',
          )
        else
          ...favoriteRestaurants.map(
            (restaurant) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RestaurantCard(
                restaurant: restaurant,
                isFavorite: true,
                onTap: () => onOpenRestaurant(restaurant),
                onFavoriteTap: () =>
                    controller.toggleFavoriteRestaurant(restaurant.id),
              ),
            ),
          ),
      ],
    );
  }
}

class AccountSavedDishesScreen extends StatelessWidget {
  const AccountSavedDishesScreen({
    super.key,
    required this.controller,
    required this.onOpenRestaurant,
  });

  final AppController controller;
  final ValueChanged<Restaurant> onOpenRestaurant;

  @override
  Widget build(BuildContext context) {
    final savedDishes = controller.savedDishes;

    return _AccountDetailScaffold(
      title: 'Platos guardados',
      subtitle: 'Todo lo que dejaste marcado para pedir después.',
      children: [
        if (savedDishes.isEmpty)
          const EmptyState(
            icon: Icons.bookmark_border_rounded,
            title: 'Sin platos guardados',
            message: 'Dale like a los platos recomendados para verlos aquí.',
          )
        else
          ...savedDishes.map(
            (dish) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AccountDishTile(
                dish: dish,
                onTap: () {
                  final restaurant = controller.restaurantById(dish.restaurantId);
                  if (restaurant != null) {
                    onOpenRestaurant(restaurant);
                  }
                },
              ),
            ),
          ),
      ],
    );
  }
}

class AccountNotificationsScreen extends StatelessWidget {
  const AccountNotificationsScreen({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final notifications = controller.notifications;
        final unreadCount = controller.unreadNotificationsCount;

        return _AccountDetailScaffold(
          title: 'Notificaciones',
          subtitle:
              'Centro unificado para pedidos, restaurantes nuevos y actividad reciente de Social.',
          children: [
            AccountSectionCard(
              child: Row(
                children: [
                  Expanded(
                    child: ProfileMetricPill(
                      label: 'Sin leer',
                      value: '$unreadCount',
                      icon: Icons.mark_chat_unread_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ProfileMetricPill(
                      label: 'Historial',
                      value: '${notifications.length}',
                      icon: Icons.notifications_rounded,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (notifications.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: controller.clearNotifications,
                  icon: const Icon(Icons.delete_sweep_rounded),
                  label: const Text('Limpiar historial'),
                ),
              ),
            if (notifications.isEmpty) ...[
              const EmptyState(
                icon: Icons.notifications_none_rounded,
                title: 'Sin notificaciones todavía',
                message:
                    'Cuando cambie un pedido o entren novedades del catálogo y Social, aparecerán aquí.',
              ),
            ] else ...[
              ...notifications.map(
                (notification) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => controller.markNotificationRead(notification.id),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: notification.isUnread
                            ? _surface
                            : Colors.white.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: _line),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: _notificationAccentColor(
                                notification.type,
                              ).withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              _notificationIcon(notification.type),
                              color: _notificationAccentColor(notification.type),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notification.title,
                                        style: GoogleFonts.sora(
                                          color: _ink,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _notificationTimeLabel(
                                        notification.createdAt,
                                      ),
                                      style: GoogleFonts.manrope(
                                        color: _muted,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  notification.message,
                                  style: GoogleFonts.manrope(
                                    color: _muted,
                                    fontWeight: FontWeight.w700,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (notification.isUnread) ...[
                            const SizedBox(width: 10),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _coral,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class AccountContentScreen extends StatefulWidget {
  const AccountContentScreen({
    super.key,
    required this.controller,
    required this.onOpenRestaurant,
  });

  final AppController controller;
  final ValueChanged<Restaurant> onOpenRestaurant;

  @override
  State<AccountContentScreen> createState() => _AccountContentScreenState();
}

class _AccountContentScreenState extends State<AccountContentScreen> {
  _AccountContentFilter _filter = _AccountContentFilter.posts;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final posts = widget.controller.currentUserPosts;
        final clips = widget.controller.currentUserClips;
        final showingPosts = _filter == _AccountContentFilter.posts;
        final isEmpty = showingPosts ? posts.isEmpty : clips.isEmpty;

        return Scaffold(
          backgroundColor: _canvas,
          appBar: AppBar(title: const Text('Mis posts y reels')),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    Text(
                      'Una vista separada para tu contenido, con cambio rápido entre posts y reels.',
                      style: GoogleFonts.manrope(
                        color: _muted,
                        fontWeight: FontWeight.w700,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AccountSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              SizedBox(
                                width: 150,
                                child: ProfileMetricPill(
                                  label: 'Posts',
                                  value: '${posts.length}',
                                  icon: Icons.grid_view_rounded,
                                ),
                              ),
                              SizedBox(
                                width: 150,
                                child: ProfileMetricPill(
                                  label: 'Reels',
                                  value: '${clips.length}',
                                  icon: Icons.play_circle_fill_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('Posts'),
                                selected: showingPosts,
                                onSelected: (_) {
                                  setState(() {
                                    _filter = _AccountContentFilter.posts;
                                  });
                                },
                              ),
                              ChoiceChip(
                                label: const Text('Reels'),
                                selected: !showingPosts,
                                onSelected: (_) {
                                  setState(() {
                                    _filter = _AccountContentFilter.reels;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isEmpty)
                      EmptyState(
                        icon: showingPosts
                            ? Icons.feed_outlined
                            : Icons.play_circle_outline_rounded,
                        title: showingPosts
                            ? 'Sin posts publicados'
                            : 'Sin reels creados',
                        message: showingPosts
                            ? 'Comparte un post en Social y lo verás reflejado aquí.'
                            : 'Cuando publiques un reel aparecerá en esta sección.',
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount =
                              constraints.maxWidth >= 430 ? 3 : 2;

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: showingPosts ? posts.length : clips.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.78,
                                ),
                            itemBuilder: (context, index) {
                              if (showingPosts) {
                                final post = posts[index];
                                return _AccountPostPreviewTile(
                                  post: post,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => FoodPostDetailScreen(
                                          controller: widget.controller,
                                          post: post,
                                          onOpenRestaurant:
                                              widget.onOpenRestaurant,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }

                              final clip = clips[index];
                              return _AccountClipPreviewTile(
                                clip: clip,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => SocialReelViewerScreen(
                                        controller: widget.controller,
                                        clipIds: clips
                                            .map((entry) => entry.id)
                                            .toList(),
                                        initialIndex: index,
                                        onOpenRestaurant:
                                            widget.onOpenRestaurant,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

enum _AccountContentFilter { posts, reels }

class _AccountDetailScaffold extends StatelessWidget {
  const _AccountDetailScaffold({
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                if (subtitle != null) ...[
                  Text(
                    subtitle!,
                    style: GoogleFonts.manrope(
                      color: _muted,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountMenuTile extends StatelessWidget {
  const _AccountMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final accent = isDestructive ? _brandRedDark : _coral;
    final iconBackground = isDestructive
        ? _brandRedDark.withValues(alpha: 0.10)
        : _coral.withValues(alpha: 0.10);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.sora(
                      color: isDestructive ? _brandRedDark : _ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      color: _muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (badge != null && badge!.trim().isNotEmpty) ...[
              Container(
                constraints: const BoxConstraints(minWidth: 34),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _line),
                ),
                child: Text(
                  badge!,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right_rounded, color: _muted),
          ],
        ),
      ),
    );
  }
}

class _AccountMenuSectionHeader extends StatelessWidget {
  const _AccountMenuSectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 8),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.manrope(
          color: _muted,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _AccountMenuDivider extends StatelessWidget {
  const _AccountMenuDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Divider(height: 1, color: _line),
    );
  }
}

class _AccountOrderCard extends StatelessWidget {
  const _AccountOrderCard({
    required this.controller,
    required this.order,
    required this.showActiveActions,
  });

  final AppController controller;
  final OrderRecord order;
  final bool showActiveActions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    showActiveActions
                        ? order.orderCode
                        : '${order.orderCode} · ${_date(order.createdAt)}',
                    style: GoogleFonts.sora(
                      fontWeight: FontWeight.w800,
                      color: _ink,
                      fontSize: showActiveActions ? 18 : 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _OrderStatusChip(status: order.status),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              showActiveActions
                  ? order.restaurantNames.join(' · ')
                  : order.items
                        .map((item) => '${item.quantity}x ${item.name}')
                        .join(' · '),
              style: GoogleFonts.manrope(
                color: showActiveActions ? _ink : _muted,
                fontWeight: FontWeight.w800,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            if (showActiveActions)
              Text(
                '${order.itemCount} productos · ETA ${order.etaLabel}',
                style: GoogleFonts.manrope(
                  color: _muted,
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              SummaryRow(
                label: 'Pago',
                value: _paymentMethodLabel(order.paymentMethod),
              ),
            const SizedBox(height: 8),
            SummaryRow(
              label: 'Total',
              value: _currency(order.total),
              emphasis: !showActiveActions,
            ),
            const SizedBox(height: 8),
            Text(
              order.deliveryAddress,
              style: GoogleFonts.manrope(color: _muted, height: 1.4),
            ),
            const SizedBox(height: 14),
            if (showActiveActions)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => controller.reorderOrder(order),
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Repetir'),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: controller.hasReviewedOrder(order.id)
                          ? null
                          : () => _showOrderRecommendationSheet(
                                context,
                                controller,
                                order,
                              ),
                      icon: Icon(
                        controller.hasReviewedOrder(order.id)
                            ? Icons.check_circle_rounded
                            : Icons.thumb_up_alt_outlined,
                      ),
                      label: Text(
                        controller.hasReviewedOrder(order.id)
                            ? 'Ya recomendado'
                            : 'Recomendar pedido',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => controller.reorderOrder(order),
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('Pedir de nuevo'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _AccountPostPreviewTile extends StatelessWidget {
  const _AccountPostPreviewTile({required this.post, required this.onTap});

  final FoodPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            post.mediaBytes != null
                ? Image.memory(post.mediaBytes!, fit: BoxFit.cover)
                : Image.asset(post.imageAsset, fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.04),
                    Colors.black.withValues(alpha: 0.80),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Post',
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    post.caption,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sora(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${post.likesLabel} · ${post.commentsLabel}',
                    style: GoogleFonts.manrope(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountClipPreviewTile extends StatelessWidget {
  const _AccountClipPreviewTile({required this.clip, required this.onTap});

  final SocialClip clip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            clip.mediaBytes != null
                ? Image.memory(clip.mediaBytes!, fit: BoxFit.cover)
                : Image.asset(clip.coverImage, fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.04),
                    Colors.black.withValues(alpha: 0.80),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.play_arrow_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              clip.durationLabel,
                              style: GoogleFonts.manrope(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        clip.viewsLabel,
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    clip.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sora(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${clip.likesLabel} · ${clip.commentsLabel}',
                    style: GoogleFonts.manrope(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RestaurantDetailScreen extends StatefulWidget {
  const RestaurantDetailScreen({
    super.key,
    required this.controller,
    required this.restaurant,
  });

  final AppController controller;
  final Restaurant restaurant;

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  var _selectedSection = 0;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final restaurant = widget.restaurant;
    final menuItems = controller.menuForRestaurant(restaurant.id);
    final restaurantPosts = controller.postsForRestaurant(restaurant.id);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final favorite = controller.favoriteRestaurantIds.contains(
          restaurant.id,
        );
        return Scaffold(
          backgroundColor: _canvas,
          appBar: AppBar(
            title: Text(restaurant.name),
            actions: [
              IconButton(
                onPressed: () =>
                    controller.toggleFavoriteRestaurant(restaurant.id),
                icon: Icon(
                  favorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CartScreen(controller: controller),
                  ),
                ),
                icon: Badge(
                  isLabelVisible: controller.cartCount > 0,
                  label: Text(controller.cartCount.toString()),
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ChatScreen(
                          controller: controller,
                          restaurant: restaurant,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: const Text('Chatear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CartScreen(controller: controller),
                      ),
                    ),
                    icon: const Icon(Icons.shopping_bag_rounded),
                    label: Text(
                      'Ver carrito${controller.cartCount > 0 ? ' (${controller.cartCount})' : ''}',
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              GalleryCarousel(
                images: restaurant.bannerAssets,
                height: 250,
                showArrows: true,
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.asset(
                              restaurant.logoAsset,
                              width: 58,
                              height: 58,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  restaurant.name,
                                  style: GoogleFonts.sora(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: _ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        restaurant.description,
                        style: GoogleFonts.manrope(color: _muted, height: 1.45),
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: restaurant.tags
                            .map(
                              (tag) => Chip(
                                label: Text(tag.toUpperCase()),
                                backgroundColor: _surface,
                                side: const BorderSide(color: _line),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      selected: _selectedSection == 0,
                      label: const SizedBox(
                        width: double.infinity,
                        child: Text('Menú', textAlign: TextAlign.center),
                      ),
                      onSelected: (_) => setState(() => _selectedSection = 0),
                      selectedColor: _coral,
                      labelStyle: GoogleFonts.manrope(
                        color: _selectedSection == 0 ? Colors.white : _ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      selected: _selectedSection == 1,
                      label: const SizedBox(
                        width: double.infinity,
                        child: Text('Social', textAlign: TextAlign.center),
                      ),
                      onSelected: (_) => setState(() => _selectedSection = 1),
                      selectedColor: _coral,
                      labelStyle: GoogleFonts.manrope(
                        color: _selectedSection == 1 ? Colors.white : _ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      selected: _selectedSection == 2,
                      label: const SizedBox(
                        width: double.infinity,
                        child: Text('Contacto', textAlign: TextAlign.center),
                      ),
                      onSelected: (_) => setState(() => _selectedSection = 2),
                      selectedColor: _coral,
                      labelStyle: GoogleFonts.manrope(
                        color: _selectedSection == 2 ? Colors.white : _ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (_selectedSection == 0)
                if (menuItems.isEmpty)
                  const EmptyState(
                    icon: Icons.menu_book_rounded,
                    title: 'Menú no disponible',
                    message:
                        'Este restaurante aún no tiene platos cargados en la aplicación.',
                  )
                else
                  ...menuItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: MenuItemCard(
                        item: item,
                        onExpanded: controller.markMenuExplored,
                        onCustomizationTap: controller.addCustomization,
                        onAddToCart: () =>
                            controller.addMenuItem(item, restaurant),
                      ),
                    ),
                  )
              else if (_selectedSection == 1)
                RestaurantSocialSection(
                  controller: controller,
                  restaurant: restaurant,
                  posts: restaurantPosts,
                )
              else
                ContactSection(
                  restaurant: restaurant,
                  onOpenMaps: () => _openMapsForRestaurant(context, restaurant),
                ),
            ],
          ),
        );
      },
    );
  }
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final TextEditingController _phoneController;
  var _isCheckoutBusy = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(
      text: widget.controller.currentUserPhone,
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _syncCheckoutFields() {
    if (_phoneController.text != widget.controller.currentUserPhone) {
      _phoneController.value = TextEditingValue(
        text: widget.controller.currentUserPhone,
        selection: TextSelection.collapsed(
          offset: widget.controller.currentUserPhone.length,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        _syncCheckoutFields();
        final activePayment = controller.paymentMethodDetails(
          controller.selectedPaymentMethod,
        );
        final checkoutActionLabel =
            controller.selectedPaymentMethod == PaymentMethodType.cash
            ? 'Pedir'
            : 'Pagar';
        return Scaffold(
          backgroundColor: _canvas,
          appBar: AppBar(title: const Text('Carrito y pago')),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: FilledButton.icon(
              onPressed: controller.cart.isEmpty || _isCheckoutBusy
                  ? null
                  : () async {
                      if (controller.deliveryAddress.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Selecciona una dirección antes de continuar.',
                            ),
                          ),
                        );
                        return;
                      }

                      if (controller.currentUserPhone.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Agrega tu número de teléfono antes de continuar.',
                            ),
                          ),
                        );
                        return;
                      }

                      setState(() {
                        _isCheckoutBusy = true;
                      });

                      final verified = await _showWhatsappAvailabilitySheet(
                        context,
                        controller,
                      );
                      if (!mounted) {
                        return;
                      }

                      setState(() {
                        _isCheckoutBusy = false;
                      });

                      if (!verified || !context.mounted) {
                        return;
                      }

                      setState(() {
                        _isCheckoutBusy = true;
                      });

                      final success = await controller.confirmOrder();
                      if (!mounted) {
                        return;
                      }

                      setState(() {
                        _isCheckoutBusy = false;
                      });

                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pedido confirmado y agregado al historial'),
                          ),
                        );
                        Navigator.of(context).pop();
                      }
                    },
              icon: _isCheckoutBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Icon(Icons.lock_rounded),
              label: Text(
                _isCheckoutBusy
                    ? 'Procesando...'
                    : '$checkoutActionLabel ${_currency(controller.payableTotal)}',
              ),
            ),
          ),
          body: controller.cart.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: EmptyState(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Carrito vacío',
                    message:
                        'Agrega platos desde el feed o desde el menú de un restaurante.',
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (controller.cartHasMultipleRestaurants) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.layers_rounded,
                                      color: Color(0xFFB85A10),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Tienes productos de ${controller.cartRestaurantCount} restaurantes. El pedido se consolidará en una sola compra.',
                                        style: GoogleFonts.manrope(
                                          color: const Color(0xFF8A4A17),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Dirección',
                                        style: GoogleFonts.sora(
                                          fontWeight: FontWeight.w800,
                                          color: _ink,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    activePayment.label.split(' ').first,
                                  ),
                                  backgroundColor: _surface,
                                  side: const BorderSide(color: _line),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Direcciones registradas',
                                        style: GoogleFonts.sora(
                                          fontWeight: FontWeight.w800,
                                          color: _ink,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Usa una dirección guardada o cambia la actual para este pedido.',
                                        style: GoogleFonts.manrope(
                                          color: _muted,
                                          fontWeight: FontWeight.w700,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      _showPersonalDataSheet(context, controller),
                                  icon: const Icon(Icons.add_location_alt_rounded),
                                  label: const Text('Cambiar'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...controller.profileSavedAddresses.map(
                              (address) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _CheckoutSavedAddressTile(
                                  address: address,
                                  selected:
                                      controller.deliveryAddress.trim() ==
                                      address.address.trim(),
                                  onTap: () =>
                                      controller.selectSavedAddressForCheckout(
                                        address,
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Número de teléfono',
                              style: GoogleFonts.sora(
                                fontWeight: FontWeight.w800,
                                color: _ink,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Asegura que tu número telefónico pueda recibir llamadas y mensajes de WhatsApp.',
                              style: GoogleFonts.manrope(
                                color: _muted,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phoneController,
                              onChanged: controller.updateCustomerPhone,
                              keyboardType: TextInputType.phone,
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w700,
                                color: _ink,
                              ),
                              decoration: _inputDecoration(
                                'Número telefónico',
                                Icons.phone_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...controller.cart.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CartItemCard(
                          item: item,
                          onIncrease: () =>
                              controller.increaseCartItem(item.id),
                          onDecrease: () =>
                              controller.decreaseCartItem(item.id),
                          onRemove: () => controller.removeCartItem(item.id),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Métodos de pago',
                              style: GoogleFonts.sora(
                                fontWeight: FontWeight.w800,
                                color: _ink,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 14),
                            ...paymentMethods.map(
                              (method) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: PaymentMethodTile(
                                  method: method,
                                  selectedType:
                                      controller.selectedPaymentMethod,
                                  selected:
                                      method.type ==
                                      controller.selectedPaymentMethod,
                                  onTap: () =>
                                      controller.setPaymentMethod(method.type),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SummaryRow(
                              label: 'Subtotal',
                              value: _currency(controller.cartTotal),
                            ),
                            const SizedBox(height: 10),
                            SummaryRow(
                              label: 'Domicilio',
                              value: _currency(controller.deliveryFee),
                            ),
                            const SizedBox(height: 10),
                            SummaryRow(
                              label: 'Servicio',
                              value: _currency(controller.serviceFee),
                            ),
                            const SizedBox(height: 10),
                            SummaryRow(
                              label: 'Pagas con',
                              value: activePayment.label,
                            ),
                            const Divider(height: 28),
                            SummaryRow(
                              label: 'Total',
                              value: _currency(controller.payableTotal),
                              emphasis: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _CheckoutSavedAddressTile extends StatelessWidget {
  const _CheckoutSavedAddressTile({
    required this.address,
    required this.selected,
    required this.onTap,
  });

  final SavedAddress address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? _coral.withValues(alpha: 0.08) : _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _coral : _line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? _coral.withValues(alpha: 0.14)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    address.label,
                    style: GoogleFonts.manrope(
                      color: selected ? _coral : _ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
                if (address.isPrimary) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Principal',
                    style: GoogleFonts.manrope(
                      color: _muted,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ],
                const Spacer(),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: _coral,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              address.address,
              style: GoogleFonts.sora(
                color: _ink,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            if (address.details.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                address.details,
                style: GoogleFonts.manrope(
                  color: _muted,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.controller,
    required this.restaurant,
  });

  final AppController controller;
  final Restaurant restaurant;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final messages = widget.controller.chatForRestaurant(
          widget.restaurant.id,
          widget.restaurant.name,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          }
        });

        return Scaffold(
          backgroundColor: _canvas,
          appBar: AppBar(title: Text('Chat con ${widget.restaurant.name}')),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                Expanded(
                  child: Card(
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(18),
                      itemCount: messages.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return Align(
                          alignment: message.isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: message.isUser ? _gold : _coral,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Text(
                                message.message,
                                style: GoogleFonts.manrope(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SearchField(
                        controller: _textController,
                        hintText: 'Escribe tu mensaje',
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: _send,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(54, 54),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _send() async {
    final message = _textController.text;
    _textController.clear();
    await widget.controller.sendChatMessage(
      restaurantId: widget.restaurant.id,
      restaurantName: widget.restaurant.name,
      message: message,
    );
  }
}

class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    this.initialValue,
    this.controller,
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
  });

  final String? initialValue;
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  TextEditingController? _internalController;

  TextEditingController get _effectiveController {
    return widget.controller ??
        (_internalController ??= TextEditingController(text: widget.initialValue ?? ''));
  }

  @override
  void didUpdateWidget(covariant SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == null) {
      final nextValue = widget.initialValue ?? '';
      if (_effectiveController.text != nextValue) {
        _effectiveController.value = TextEditingValue(
          text: nextValue,
          selection: TextSelection.collapsed(offset: nextValue.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 380;

    return TextFormField(
      controller: _effectiveController,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: _ink),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: GoogleFonts.manrope(color: _muted),
        prefixIcon: const Icon(Icons.search_rounded, color: _coral),
        isDense: compact,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: compact ? 14 : 18,
        ),
        filled: true,
        fillColor: _card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: _line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: _line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: _coral, width: 1.3),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.eyebrow, required this.title});

  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 380;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: GoogleFonts.manrope(
            color: _coral,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.sora(
            color: _ink,
            fontWeight: FontWeight.w800,
            fontSize: compact ? 18 : 21,
          ),
        ),
      ],
    );
  }
}

class PromoCarousel extends StatefulWidget {
  const PromoCarousel({
    super.key,
    required this.promotions,
    required this.onTap,
  });

  final List<PromoCampaign> promotions;
  final ValueChanged<PromoCampaign> onTap;

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  late final PageController _pageController;
  Timer? _autoPlayTimer;
  var _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.95);
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    if (widget.promotions.length <= 1) {
      return;
    }
    _autoPlayTimer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (!mounted || !_pageController.hasClients) {
        return;
      }
      final nextPage = (_page + 1) % widget.promotions.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.promotions.isEmpty) {
      return const EmptyState(
        icon: Icons.local_offer_outlined,
        title: 'Sin promociones activas',
        message:
            'Cambia de categoría o vuelve más tarde para revisar nuevas ofertas.',
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 308,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                _autoPlayTimer?.cancel();
              }
              if (notification is ScrollEndNotification) {
                _startAutoPlay();
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.promotions.length,
              onPageChanged: (value) => setState(() => _page = value),
              itemBuilder: (context, index) {
                final promo = widget.promotions[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () => widget.onTap(promo),
                    borderRadius: BorderRadius.circular(34),
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(34),
                        border: Border.all(color: _line),
                        boxShadow: [
                          BoxShadow(
                            color: _coral.withValues(alpha: 0.16),
                            blurRadius: 24,
                            offset: const Offset(0, 14),
                          ),
                        ],
                        image: DecorationImage(
                          image: AssetImage(promo.imageAsset),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(34),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.02),
                              Colors.black.withValues(alpha: 0.16),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'PROMO',
                                    style: GoogleFonts.manrope(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              promo.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.sora(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.local_offer_rounded,
                                        color: _coral,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Ver restaurante',
                                        style: GoogleFonts.manrope(
                                          color: _ink,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${index + 1}/${widget.promotions.length}',
                                  style: GoogleFonts.manrope(
                                    color: Colors.white.withValues(alpha: 0.84),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.promotions.length, (index) {
            final active = index == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: active ? 30 : 10,
              height: 10,
              decoration: BoxDecoration(
                gradient: active
                    ? const LinearGradient(colors: [_coral, Color(0xFFF06A23)])
                    : null,
                color: active ? null : _line,
                borderRadius: BorderRadius.circular(999),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: _coral.withValues(alpha: 0.22),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class FastDeliveryCard extends StatelessWidget {
  const FastDeliveryCard({
    super.key,
    required this.restaurant,
    required this.onTap,
    required this.description,
    this.accentLabel,
    this.accentColor = const Color(0xFF248043),
    this.accentBackground = const Color(0xFFE8F8EC),
  });

  final Restaurant restaurant;
  final VoidCallback onTap;
  final String description;
  final String? accentLabel;
  final Color accentColor;
  final Color accentBackground;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _line),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  restaurant.logoAsset,
                  width: 74,
                  height: 74,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            restaurant.name,
                            style: GoogleFonts.sora(
                              fontWeight: FontWeight.w800,
                              color: _ink,
                              fontSize: 17,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: accentBackground,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            accentLabel ?? restaurant.deliveryTime,
                            style: GoogleFonts.manrope(
                              color: accentColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: GoogleFonts.manrope(color: _muted, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MapRestaurantCard extends StatelessWidget {
  const MapRestaurantCard({
    super.key,
    required this.restaurant,
    required this.onTap,
    required this.onOpenMaps,
  });

  final Restaurant restaurant;
  final VoidCallback onTap;
  final VoidCallback onOpenMaps;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                restaurant.logoAsset,
                width: 76,
                height: 76,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: GoogleFonts.sora(
                            color: _ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      if (restaurant.isHot) const _HotBadge(label: 'Hot'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    restaurant.address,
                    style: GoogleFonts.manrope(
                      color: _muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.storefront_rounded),
                        label: const Text('Ver'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: onOpenMaps,
                        icon: const Icon(Icons.map_rounded),
                        label: const Text('OSM'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RestaurantMapExplorer extends StatefulWidget {
  const RestaurantMapExplorer({
    super.key,
    required this.restaurants,
    required this.onSelectRestaurant,
    this.selectedRestaurant,
    this.userLocation,
  });

  final List<Restaurant> restaurants;
  final ValueChanged<Restaurant> onSelectRestaurant;
  final Restaurant? selectedRestaurant;
  final LatLng? userLocation;

  @override
  State<RestaurantMapExplorer> createState() => _RestaurantMapExplorerState();
}

class _RestaurantMapExplorerState extends State<RestaurantMapExplorer> {
  late final fm.MapController _mapController;

  void focusOnCoordinates(LatLng target, {double zoom = 15}) {
    _mapController.move(target, zoom);
  }

  void resetToPasto() {
    _mapController.move(_pastoCenter, 13.2);
  }

  @override
  void initState() {
    super.initState();
    _mapController = fm.MapController();
  }

  @override
  void didUpdateWidget(covariant RestaurantMapExplorer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selected = widget.selectedRestaurant;
    if (selected != null && oldWidget.selectedRestaurant?.id != selected.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _mapController.move(
          LatLng(selected.latitude, selected.longitude),
          15,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFFF9F4ED), Color(0xFFF1E2D3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: fm.FlutterMap(
            mapController: _mapController,
            options: const fm.MapOptions(
              initialCenter: _pastoCenter,
              initialZoom: 13.2,
              interactionOptions: fm.InteractionOptions(
                flags: fm.InteractiveFlag.drag |
                    fm.InteractiveFlag.pinchZoom |
                    fm.InteractiveFlag.doubleTapZoom,
              ),
            ),
            children: [
              fm.TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.urkufood',
              ),
              fm.MarkerLayer(
                markers: [
                  if (widget.userLocation != null)
                    fm.Marker(
                      point: widget.userLocation!,
                      width: 28,
                      height: 28,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2F80ED),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ...widget.restaurants.map((restaurant) {
                    final selected = widget.selectedRestaurant?.id == restaurant.id;
                    return fm.Marker(
                      point: LatLng(restaurant.latitude, restaurant.longitude),
                      width: selected ? 138 : 122,
                      height: selected ? 62 : 54,
                      child: GestureDetector(
                        onTap: () => widget.onSelectRestaurant(restaurant),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? _gold
                                    : (restaurant.isHot ? _coral : _ink),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 10,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    selected
                                        ? Icons.my_location_rounded
                                        : (restaurant.isHot
                                            ? Icons.local_fire_department_rounded
                                            : Icons.location_on_rounded),
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      restaurant.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.manrope(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: selected ? 12 : 10,
                              height: selected ? 12 : 10,
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.white
                                    : (restaurant.isHot ? _gold : _coral),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeaturedRestaurantCard extends StatelessWidget {
  const FeaturedRestaurantCard({
    super.key,
    required this.restaurant,
    required this.onTap,
  });

  final Restaurant restaurant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 208,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _line),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      restaurant.logoAsset,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    restaurant.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sora(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                      height: 1.15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeRestaurantSpotlightCard extends StatelessWidget {
  const HomeRestaurantSpotlightCard({
    super.key,
    required this.restaurant,
    required this.dishes,
    required this.isFavorite,
    required this.onOpenRestaurant,
    required this.onFavoriteTap,
    required this.onAddDish,
  });

  final Restaurant restaurant;
  final List<MenuItemModel> dishes;
  final bool isFavorite;
  final VoidCallback onOpenRestaurant;
  final VoidCallback onFavoriteTap;
  final ValueChanged<MenuItemModel> onAddDish;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpenRestaurant,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  dishes.first.coverImage,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      restaurant.logoAsset,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          restaurant.name,
                          style: GoogleFonts.sora(
                            color: _ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${restaurant.deliveryTime} · ${restaurant.priceRange} · aleatorio ahora',
                          style: GoogleFonts.manrope(
                            color: _coral,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: onFavoriteTap,
                    style: IconButton.styleFrom(
                      backgroundColor: _canvas,
                      foregroundColor: _coral,
                    ),
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                restaurant.description,
                style: GoogleFonts.manrope(
                  color: _muted,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              ...dishes.map(
                (dish) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _line),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dish.name,
                                style: GoogleFonts.sora(
                                  color: _ink,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dish.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.manrope(
                                  color: _muted,
                                  fontWeight: FontWeight.w700,
                                  height: 1.35,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _currency(dish.price),
                              style: GoogleFonts.sora(
                                color: _coral,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FilledButton.tonalIcon(
                              onPressed: () => onAddDish(dish),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Agregar'),
                              style: FilledButton.styleFrom(
                                backgroundColor: _coral.withValues(alpha: 0.10),
                                foregroundColor: _coral,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onOpenRestaurant,
                  icon: const Icon(Icons.storefront_rounded),
                  label: const Text('Ver restaurante'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SurpriseCard extends StatelessWidget {
  const SurpriseCard({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [_coral, _gold],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Modo sorpresa',
              style: GoogleFonts.sora(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Si no sabes qué pedir, la app elige un plato por ti y además te regala puntos extra.',
              style: GoogleFonts.manrope(
                color: Colors.white.withValues(alpha: 0.92),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _coralDark,
              ),
              onPressed: onPressed,
              icon: const Icon(Icons.casino_rounded),
              label: const Text('Elegir por mí'),
            ),
          ],
        ),
      ),
    );
  }
}

class RecommendedDishCard extends StatelessWidget {
  const RecommendedDishCard({
    super.key,
    required this.dish,
    required this.liked,
    required this.onTap,
    required this.onAdd,
    required this.onLike,
  });

  final RecommendedDish dish;
  final bool liked;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback? onLike;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: Image.asset(
                dish.imageAsset,
                height: 240,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dish.dishName,
                          style: GoogleFonts.sora(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                      ),
                      Text(
                        _currency(dish.price),
                        style: GoogleFonts.sora(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _coral,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dish.restaurantName,
                    style: GoogleFonts.manrope(
                      color: _coral,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    dish.description,
                    style: GoogleFonts.manrope(color: _muted, height: 1.45),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onAdd,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Agregar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: onLike,
                        icon: Icon(
                          liked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                        ),
                        label: Text(liked ? 'Guardado' : 'Me gusta'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RestaurantCard extends StatelessWidget {
  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteTap,
    this.showMetaLine = true,
  });

  final Restaurant restaurant;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final bool showMetaLine;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _line),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  restaurant.logoAsset,
                  width: 92,
                  height: 92,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            restaurant.name,
                            style: GoogleFonts.sora(
                              fontWeight: FontWeight.w800,
                              color: _ink,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: onFavoriteTap,
                          icon: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: _coral,
                          ),
                        ),
                      ],
                    ),
                    if (restaurant.isHot) ...[
                      const SizedBox(height: 4),
                      const _HotBadge(label: 'Vendiendo bastante'),
                    ],
                    if (showMetaLine) ...[
                      const SizedBox(height: 4),
                      Text(
                        '⭐ ${restaurant.rating} · ${restaurant.deliveryTime} · ${restaurant.priceRange}',
                        style: GoogleFonts.manrope(
                          color: _coral,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ] else
                      const SizedBox(height: 6),
                    Text(
                      restaurant.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(color: _muted, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RewardPointsCard extends StatelessWidget {
  const RewardPointsCard({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFFFBE3CF), Color(0xFFFFF6E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _coral,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                controller.levelName,
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${controller.points} puntos',
              style: GoogleFonts.sora(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nivel ${controller.levelNumber} · Sigue acumulando para desbloquear premios mayores.',
              style: GoogleFonts.manrope(
                color: _muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: (controller.points % 200) / 200,
                backgroundColor: Colors.white,
                valueColor: const AlwaysStoppedAnimation<Color>(_coral),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TriviaCard extends StatelessWidget {
  const TriviaCard({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final question = controller.currentTriviaQuestion;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trivia gastronómica',
              style: GoogleFonts.sora(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Responde bien y suma puntos. Aunque falles, participas y avanzas.',
              style: GoogleFonts.manrope(color: _muted, height: 1.4),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.question,
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      color: _ink,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(question.options.length, (index) {
                    final selected = controller.selectedTriviaOption == index;
                    final answered = controller.selectedTriviaOption != null;
                    final isCorrect = question.correctIndex == index;
                    final background = answered
                        ? isCorrect
                              ? const Color(0xFFE5F7EB)
                              : selected
                              ? const Color(0xFFFDE7E7)
                              : _card
                        : _card;
                    final borderColor = answered
                        ? isCorrect
                              ? const Color(0xFF2E9B4C)
                              : selected
                              ? _coral
                              : _line
                        : _line;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: answered
                            ? null
                            : () => controller.answerTrivia(index),
                        borderRadius: BorderRadius.circular(20),
                        child: Ink(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: background,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: _gold.withValues(alpha: 0.25),
                                foregroundColor: _ink,
                                child: Text(String.fromCharCode(65 + index)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  question.options[index],
                                  style: GoogleFonts.manrope(
                                    color: _ink,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            if (controller.selectedTriviaOption != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: controller.lastTriviaAnswerCorrect == true
                      ? const Color(0xFFE5F7EB)
                      : const Color(0xFFFDE7E7),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  controller.lastTriviaAnswerCorrect == true
                      ? 'Respuesta correcta. Ganaste 25 puntos.'
                      : 'No era esa. La correcta es ${question.options[question.correctIndex]}. Ganaste 5 puntos por participar.',
                  style: GoogleFonts.manrope(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: controller.nextTriviaQuestion,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(
                  'Siguiente pregunta · ${controller.triviaScore} pts',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ChallengeCard extends StatelessWidget {
  const ChallengeCard({
    super.key,
    required this.challenge,
    required this.onComplete,
  });

  final RewardChallenge challenge;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: challenge.completed ? const Color(0xFFE5F7EB) : _surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                challenge.completed
                    ? Icons.check_circle_rounded
                    : Icons.bolt_rounded,
                color: challenge.completed ? const Color(0xFF2E9B4C) : _coral,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title,
                    style: GoogleFonts.sora(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    challenge.description,
                    style: GoogleFonts.manrope(color: _muted, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            challenge.completed
                ? Chip(
                    label: const Text('Completado'),
                    backgroundColor: const Color(0xFFE5F7EB),
                    side: BorderSide.none,
                    labelStyle: GoogleFonts.manrope(
                      color: const Color(0xFF2E9B4C),
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : FilledButton(
                    onPressed: onComplete,
                    child: Text('+${challenge.points} pts'),
                  ),
          ],
        ),
      ),
    );
  }
}

class RewardWheelCard extends StatefulWidget {
  const RewardWheelCard({super.key, required this.controller});

  final AppController controller;

  @override
  State<RewardWheelCard> createState() => _RewardWheelCardState();
}

class _RewardWheelCardState extends State<RewardWheelCard> {
  double _turns = 0;
  String? _lastPrize;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(eyebrow: 'Ruleta', title: 'Gira por premios'),
            const SizedBox(height: 18),
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: _turns),
                duration: const Duration(milliseconds: 1400),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.rotate(angle: value * math.pi, child: child);
                },
                child: GestureDetector(
                  onTap: _spin,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const SweepGradient(
                        colors: [_coral, _gold, _olive, _coral],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _coral.withValues(alpha: 0.22),
                          blurRadius: 26,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 126,
                        height: 126,
                        decoration: const BoxDecoration(
                          color: _surface,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'GIRAR',
                          style: GoogleFonts.sora(
                            fontWeight: FontWeight.w800,
                            color: _ink,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _lastPrize == null
                  ? 'Toca la ruleta para ganar recompensas.'
                  : 'Último premio: $_lastPrize',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                color: _muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _spin() {
    setState(() {
      _turns += 4 + math.Random().nextDouble() * 3;
      _lastPrize = widget.controller.spinWheel();
    });
  }
}

class MenuItemCard extends StatefulWidget {
  const MenuItemCard({
    super.key,
    required this.item,
    required this.onExpanded,
    required this.onCustomizationTap,
    required this.onAddToCart,
  });

  final MenuItemModel item;
  final VoidCallback onExpanded;
  final ValueChanged<String> onCustomizationTap;
  final VoidCallback onAddToCart;

  @override
  State<MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends State<MenuItemCard> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _toggle,
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        item.coverImage,
                        width: 92,
                        height: 92,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: GoogleFonts.sora(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.description,
                            style: GoogleFonts.manrope(
                              color: _muted,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _currency(item.price),
                            style: GoogleFonts.sora(
                              fontWeight: FontWeight.w800,
                              color: _coral,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: _coral,
                      size: 30,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 280),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GalleryCarousel(images: item.galleryImages, height: 210),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InfoBadge(
                            icon: Icons.local_fire_department_rounded,
                            label: 'Calorías',
                            value: item.calories,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InfoBadge(
                            icon: Icons.schedule_rounded,
                            label: 'Preparación',
                            value: item.prepTime,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ingredientes',
                      style: GoogleFonts.sora(
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.ingredients.join(', '),
                      style: GoogleFonts.manrope(color: _muted, height: 1.45),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Personalización',
                      style: GoogleFonts.sora(
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: item.customizations.map((customization) {
                        return ActionChip(
                          onPressed: () =>
                              widget.onCustomizationTap(customization),
                          label: Text(customization),
                          backgroundColor: _surface,
                          side: const BorderSide(color: _line),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: widget.onAddToCart,
                      icon: const Icon(Icons.add_shopping_cart_rounded),
                      label: const Text('Agregar al carrito'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
    });
    if (_expanded) {
      widget.onExpanded();
    }
  }
}

class RestaurantSocialSection extends StatelessWidget {
  const RestaurantSocialSection({
    super.key,
    required this.controller,
    required this.restaurant,
    required this.posts,
  });

  final AppController controller;
  final Restaurant restaurant;
  final List<FoodPost> posts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          eyebrow: 'Recomendaciones',
          title: 'Que recomiendan de este restaurante',
        ),
        const SizedBox(height: 14),
        if (posts.isEmpty)
          EmptyState(
            icon: Icons.thumb_up_alt_outlined,
            title: 'Sin recomendaciones todavia',
            message:
                'Cuando un pedido tenga una buena experiencia, aparecera aqui como recomendacion verificada.',
          )
        else
          ...posts.map(
            (post) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: FoodPostCard(
                post: post,
                onOpenPost: () {},
                onLike: () => controller.toggleFoodPostLike(post.id),
                onComment: () {},
                showCommentAction: false,
                onOpenRestaurant: () {},
              ),
            ),
          ),
      ],
    );
  }
}

class RestaurantCommentCard extends StatelessWidget {
  const RestaurantCommentCard({
    super.key,
    required this.comment,
    required this.onLike,
  });

  final RestaurantComment comment;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _canvas,
                  child: Text(
                    comment.author.substring(0, 1),
                    style: GoogleFonts.sora(
                      color: _coral,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.author,
                        style: GoogleFonts.sora(
                          color: _ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${comment.handle} · ${comment.timeLabel}',
                        style: GoogleFonts.manrope(
                          color: _muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: onLike,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          comment.likedByCurrentUser
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color:
                              comment.likedByCurrentUser ? _coral : _muted,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          comment.likesLabel,
                          style: GoogleFonts.manrope(
                            color: _ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              comment.message,
              style: GoogleFonts.manrope(
                color: _ink,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContactSection extends StatelessWidget {
  const ContactSection({
    super.key,
    required this.restaurant,
    required this.onOpenMaps,
  });

  final Restaurant restaurant;
  final VoidCallback onOpenMaps;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                restaurant.contactPhotoAsset,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              restaurant.contactName,
              style: GoogleFonts.sora(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: _ink,
              ),
            ),
            const SizedBox(height: 12),
            ContactRow(icon: Icons.phone_rounded, text: restaurant.phone),
            const SizedBox(height: 10),
            ContactRow(
              icon: Icons.location_on_rounded,
              text: restaurant.address,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onOpenMaps,
              icon: const Icon(Icons.map_rounded),
              label: const Text('Abrir ubicación en OpenStreetMap'),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SocialChip(
                  icon: Icons.camera_alt_rounded,
                  label: restaurant.instagram,
                ),
                SocialChip(
                  icon: Icons.facebook_rounded,
                  label: restaurant.facebook,
                ),
                const SocialChip(icon: Icons.chat_rounded, label: 'WhatsApp'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showOrderRecommendationSheet(
  BuildContext context,
  AppController controller,
  OrderRecord order,
) async {
  bool? recommendChoice;
  final selectedReasons = <String>{};

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final itemName = order.items.isNotEmpty ? order.items.first.name : 'tu pedido';
          final restaurantName = order.restaurantNames.isNotEmpty
              ? order.restaurantNames.first
              : 'el restaurante';

          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              24,
              16,
              16 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(28),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 52,
                        height: 5,
                        decoration: BoxDecoration(
                          color: _line,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '¿Recomiendas este pedido?',
                      style: GoogleFonts.sora(
                        color: _ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$itemName · $restaurantName',
                      style: GoogleFonts.manrope(
                        color: _muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            selected: recommendChoice == true,
                            label: const Text('Sí, lo recomiendo'),
                            onSelected: (_) {
                              setModalState(() {
                                recommendChoice = true;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            selected: recommendChoice == false,
                            label: const Text('No lo recomiendo'),
                            onSelected: (_) {
                              setModalState(() {
                                recommendChoice = false;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    if (recommendChoice == true) ...[
                      const SizedBox(height: 18),
                      Text(
                        'Selecciona lo mejor de la experiencia',
                        style: GoogleFonts.sora(
                          color: _ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Esto se convertira en una recomendacion publica dentro de Social.',
                        style: GoogleFonts.manrope(
                          color: _muted,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _guidedRecommendationOptions.map((option) {
                          final selected = selectedReasons.contains(option);
                          return FilterChip(
                            label: Text(option),
                            selected: selected,
                            onSelected: (value) {
                              setModalState(() {
                                if (value) {
                                  if (selectedReasons.length < 3) {
                                    selectedReasons.add(option);
                                  }
                                } else {
                                  selectedReasons.remove(option);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: selectedReasons.isEmpty
                              ? null
                              : () async {
                                  final published = await controller
                                      .submitOrderRecommendation(
                                    order: order,
                                    recommend: true,
                                    selectedReasons: selectedReasons.toList(),
                                  );
                                  if (published && sheetContext.mounted) {
                                    Navigator.of(sheetContext).pop();
                                  }
                                },
                          icon: const Icon(Icons.thumb_up_alt_rounded),
                          label: const Text('Publicar recomendacion'),
                        ),
                      ),
                    ] else if (recommendChoice == false) ...[
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFF7F0), Color(0xFFFBE8DE)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _line),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Icon(
                                Icons.mark_email_read_rounded,
                                color: _coral,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Muchas gracias por tu comentario',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.sora(
                                color: _ink,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tu respuesta sera enviada al restaurante y no se publicara en el feed social.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.manrope(
                                color: _muted,
                                fontWeight: FontWeight.w700,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () async {
                            final sent = await controller.submitOrderRecommendation(
                              order: order,
                              recommend: false,
                            );
                            if (sent && sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                          },
                          icon: const Icon(Icons.send_rounded),
                          label: const Text('Enviar al restaurante'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Future<bool> _showWhatsappAvailabilitySheet(
  BuildContext context,
  AppController controller,
) async {
  if (controller.cart.isEmpty) {
    return false;
  }

  final groupedItems = <int, List<CartItem>>{};
  for (final item in controller.cart) {
    groupedItems.putIfAbsent(item.restaurantId, () => <CartItem>[]).add(item);
  }

  final restaurants = groupedItems.entries
      .map((entry) {
        final restaurant = controller.restaurantById(entry.key);
        if (restaurant == null) {
          return null;
        }
        return MapEntry(restaurant, entry.value);
      })
      .whereType<MapEntry<Restaurant, List<CartItem>>>()
      .toList();

  if (restaurants.isEmpty) {
    return true;
  }

  final session = await controller.startCheckoutAvailabilityCheck(
    restaurants: restaurants
        .map(
          (entry) => AvailabilityRestaurantRequest(
            restaurantId: '${entry.key.id}',
            restaurantName: entry.key.name,
            restaurantPhone: _availabilityValidationPhone,
            contactName: entry.key.contactName,
            items: entry.value
                .map(
                  (item) => AvailabilityCheckItem(
                    name: item.name,
                    quantity: item.quantity,
                  ),
                )
                .toList(),
          ),
        )
        .toList(),
  );

  if (session == null) {
    if (!context.mounted) {
      return false;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'La validación automática no está disponible en este backend. Usaremos confirmación manual por WhatsApp.',
        ),
      ),
    );
    return _showLegacyWhatsappAvailabilitySheet(
      context,
      controller,
      restaurants,
    );
  }

  if (!context.mounted) {
    return false;
  }

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _WhatsappAvailabilitySheetContent(
      controller: controller,
      initialSession: session,
    ),
  );

  return result ?? false;
}

Future<bool> _showLegacyWhatsappAvailabilitySheet(
  BuildContext context,
  AppController controller,
  List<MapEntry<Restaurant, List<CartItem>>> restaurants,
) async {
  final confirmedRestaurants = <int>{};

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              24,
              16,
              16 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(28),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 52,
                        height: 5,
                        decoration: BoxDecoration(
                          color: _line,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Confirma disponibilidad por WhatsApp',
                      style: GoogleFonts.sora(
                        color: _ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nos aseguramos de que tu restaurante pueda cumplir con tus platillos. Mientras el backend nuevo se despliega, confirma manualmente por WhatsApp y marca cuando te respondan.',
                      style: GoogleFonts.manrope(
                        color: _muted,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ...restaurants.map((entry) {
                      final restaurant = entry.key;
                      final items = entry.value;
                      final confirmed = confirmedRestaurants.contains(
                        restaurant.id,
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _canvas,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: _line),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      restaurant.name,
                                      style: GoogleFonts.sora(
                                        color: _ink,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: confirmed
                                          ? _olive.withValues(alpha: 0.12)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(color: _line),
                                    ),
                                    child: Text(
                                      confirmed ? 'Confirmado' : 'Pendiente',
                                      style: GoogleFonts.manrope(
                                        color: confirmed ? _olive : _muted,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                items
                                    .map(
                                      (item) => '${item.quantity}x ${item.name}',
                                    )
                                    .join(' · '),
                                style: GoogleFonts.manrope(
                                  color: _muted,
                                  fontWeight: FontWeight.w700,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        await _openWhatsappAvailabilityChat(
                                          context,
                                          restaurant: restaurant,
                                          items: items,
                                          deliveryAddress:
                                              controller.deliveryAddress,
                                        );
                                      },
                                      icon: const Icon(Icons.chat_rounded),
                                      label: const Text('Abrir WhatsApp'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: FilledButton.tonalIcon(
                                      onPressed: () {
                                        setModalState(() {
                                          if (confirmed) {
                                            confirmedRestaurants.remove(
                                              restaurant.id,
                                            );
                                          } else {
                                            confirmedRestaurants.add(
                                              restaurant.id,
                                            );
                                          }
                                        });
                                      },
                                      icon: Icon(
                                        confirmed
                                            ? Icons.check_circle_rounded
                                            : Icons.radio_button_unchecked_rounded,
                                      ),
                                      label: Text(
                                        confirmed
                                            ? 'Ya me confirmaron'
                                            : 'Marcar confirmado',
                                      ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: confirmed
                                            ? _olive.withValues(alpha: 0.16)
                                            : _coral.withValues(alpha: 0.10),
                                        foregroundColor: confirmed
                                            ? _olive
                                            : _coral,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: confirmedRestaurants.length == restaurants.length
                            ? () => Navigator.of(sheetContext).pop(true)
                            : null,
                        icon: const Icon(Icons.verified_rounded),
                        label: const Text('Continuar con el pedido'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );

  return result ?? false;
}

Future<void> _openWhatsappAvailabilityChat(
  BuildContext context, {
  required Restaurant restaurant,
  required List<CartItem> items,
  required String deliveryAddress,
}) async {
  final phone = _availabilityValidationPhone;
  if (phone.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este restaurante no tiene número de WhatsApp disponible.'),
        ),
      );
    }
    return;
  }

  final itemLines = items
      .map((item) => '- ${item.quantity}x ${item.name}')
      .join('\n');
  final message = [
    'Hola ${restaurant.contactName},',
    'te escribimos desde La Carta para confirmar disponibilidad antes del cobro:',
    '',
    itemLines,
    '',
    'Dirección de entrega: $deliveryAddress',
    '¿Me confirmas si todo está disponible?',
  ].join('\n');

  final url = Uri.parse(
    'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
  );
  final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo abrir WhatsApp.')),
    );
  }
}

class _WhatsappAvailabilitySheetContent extends StatefulWidget {
  const _WhatsappAvailabilitySheetContent({
    required this.controller,
    required this.initialSession,
  });

  final AppController controller;
  final AvailabilityCheckSession initialSession;

  @override
  State<_WhatsappAvailabilitySheetContent> createState() =>
      _WhatsappAvailabilitySheetContentState();
}

class _WhatsappAvailabilitySheetContentState
    extends State<_WhatsappAvailabilitySheetContent> {
  late AvailabilityCheckSession _session;
  Timer? _pollingTimer;
  bool _isRefreshing = false;
  bool _isResolving = false;

  @override
  void initState() {
    super.initState();
    _session = widget.initialSession;
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _refreshSession(),
    );
    unawaited(_refreshSession());
  }

  Future<void> _refreshSession() async {
    if (_isRefreshing || _session.isCancelled) {
      return;
    }

    _isRefreshing = true;
    final updated = await widget.controller.refreshCheckoutAvailabilityCheck(
      _session.id,
    );
    _isRefreshing = false;

    if (!mounted || updated == null) {
      return;
    }

    setState(() {
      _session = updated;
    });

    if (_session.isReady || _session.isBlocked || _session.isCancelled) {
      _pollingTimer?.cancel();
    }
  }

  Future<void> _continueWithIssue(String restaurantId) async {
    if (_isResolving) {
      return;
    }

    setState(() {
      _isResolving = true;
    });

    final updated = await widget.controller.continueCheckoutWithIngredientIssue(
      sessionId: _session.id,
      restaurantId: restaurantId,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isResolving = false;
      if (updated != null) {
        _session = updated;
      }
    });

    if (_session.isReady) {
      _pollingTimer?.cancel();
    }
  }

  Future<void> _cancelValidation() async {
    await widget.controller.cancelCheckoutAvailabilityCheck(_session.id);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final actionLabel =
        widget.controller.selectedPaymentMethod == PaymentMethodType.cash
        ? 'Pedir'
        : 'Pagar';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        24,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 52,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Confirma disponibilidad por WhatsApp',
                style: GoogleFonts.sora(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nos aseguramos de que tu restaurante pueda cumplir con tus platillos. Espera su confirmación para continuar con el cobro.',
                style: GoogleFonts.manrope(
                  color: _muted,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              ..._session.restaurants.map((restaurant) {
                final iconColor = restaurant.isConfirmed
                    ? _olive
                    : restaurant.isDishUnavailable || restaurant.isError
                    ? _coral
                    : restaurant.isIngredientUnavailable
                    ? _gold
                    : _muted;
                final statusIcon = restaurant.isConfirmed
                    ? Icons.check_circle_rounded
                    : restaurant.isDishUnavailable || restaurant.isError
                    ? Icons.cancel_rounded
                    : restaurant.isIngredientUnavailable
                    ? Icons.remove_circle_rounded
                    : Icons.schedule_rounded;
                final statusLabel = restaurant.isConfirmed
                    ? 'Confirmado'
                    : restaurant.isDishUnavailable || restaurant.isError
                    ? 'Novedad'
                    : restaurant.isIngredientUnavailable
                    ? 'Ingrediente faltante'
                    : 'Validando';
                final observationText = restaurant.isIngredientUnavailable
                  ? restaurant.unavailableIngredient.trim()
                  : '';
                final statusMessage = restaurant.isConfirmed
                    ? 'El restaurante confirmó tu pedido.'
                    : restaurant.isDishUnavailable
                    ? '${restaurant.unavailableItemName} no está disponible.'
                    : restaurant.isIngredientUnavailable
                  ? '${restaurant.unavailableItemName} tiene una novedad reportada por el restaurante.'
                    : restaurant.isError
                    ? (restaurant.note.isEmpty
                          ? 'No pudimos contactar al restaurante por WhatsApp.'
                          : restaurant.note)
                    : (restaurant.note.isEmpty
                          ? 'El restaurante está validando tu pedido.'
                          : restaurant.note);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _canvas,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                restaurant.restaurantName,
                                style: GoogleFonts.sora(
                                  color: _ink,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: restaurant.isConfirmed
                                    ? _olive.withValues(alpha: 0.12)
                                    : restaurant.isIngredientUnavailable
                                    ? _gold.withValues(alpha: 0.18)
                                    : restaurant.isDishUnavailable ||
                                          restaurant.isError
                                    ? _coral.withValues(alpha: 0.12)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: _line),
                              ),
                              child: Text(
                                statusLabel,
                                style: GoogleFonts.manrope(
                                  color: restaurant.isConfirmed
                                      ? _olive
                                      : restaurant.isIngredientUnavailable
                                      ? const Color(0xFF9A6A00)
                                      : restaurant.isDishUnavailable ||
                                            restaurant.isError
                                      ? _coral
                                      : _muted,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          restaurant.items
                              .map(
                                (item) => '${item.quantity}x ${item.name}',
                              )
                              .join(' · '),
                          style: GoogleFonts.manrope(
                            color: _muted,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(statusIcon, color: iconColor, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    statusMessage,
                                    style: GoogleFonts.manrope(
                                      color: _ink,
                                      fontWeight: FontWeight.w800,
                                      height: 1.35,
                                    ),
                                  ),
                                  if (observationText.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Observaciones: $observationText',
                                      style: GoogleFonts.manrope(
                                        color: _muted,
                                        fontWeight: FontWeight.w800,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (restaurant.needsContinueDecision) ...[
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isResolving
                                      ? null
                                      : _cancelValidation,
                                  child: const Text('Cancelar pedido'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.tonal(
                                  onPressed: _isResolving
                                      ? null
                                      : () => _continueWithIssue(
                                            restaurant.restaurantId,
                                          ),
                                  child: const Text(
                                    'Continuar de todas formas',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              if (_session.isBlocked) ...[
                Text(
                  'Hay una novedad en tu pedido. Revísala antes de continuar.',
                  style: GoogleFonts.manrope(
                    color: _coral,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _session.isReady
                      ? () => Navigator.of(context).pop(true)
                      : null,
                  icon: Icon(
                    _session.isReady
                        ? Icons.verified_rounded
                        : Icons.schedule_rounded,
                  ),
                  label: Text(
                    _session.isReady
                        ? '$actionLabel ${_currency(widget.controller.payableTotal)}'
                        : _session.needsUserAction
                        ? 'Responde la novedad para continuar'
                        : _session.isBlocked
                        ? 'Pedido con novedades'
                        : 'El restaurante está validando tu pedido',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _openMapsForRestaurant(
  BuildContext context,
  Restaurant restaurant,
) async {
  final url = Uri.parse(
    'https://www.openstreetmap.org/?mlat=${restaurant.latitude}&mlon=${restaurant.longitude}#map=17/${restaurant.latitude}/${restaurant.longitude}',
  );
  final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo abrir OpenStreetMap.')),
    );
  }
}

void _openNotificationsCenter(BuildContext context, AppController controller) {
  controller.markAllNotificationsRead();
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AccountNotificationsScreen(controller: controller),
    ),
  );
}

class GalleryCarousel extends StatefulWidget {
  const GalleryCarousel({
    super.key,
    required this.images,
    required this.height,
    this.showArrows = false,
  });

  final List<String> images;
  final double height;
  final bool showArrows;

  @override
  State<GalleryCarousel> createState() => _GalleryCarouselState();
}

class _GalleryCarouselState extends State<GalleryCarousel> {
  late final PageController _controller;
  var _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: SizedBox(
            height: widget.height,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) {
                return Image.asset(widget.images[index], fit: BoxFit.cover);
              },
            ),
          ),
        ),
        if (widget.showArrows && widget.images.length > 1) ...[
          Positioned(
            left: 10,
            child: _CarouselArrow(
              icon: Icons.chevron_left_rounded,
              onTap: () => _move(-1),
            ),
          ),
          Positioned(
            right: 10,
            child: _CarouselArrow(
              icon: Icons.chevron_right_rounded,
              onTap: () => _move(1),
            ),
          ),
        ],
        if (widget.images.length > 1)
          Positioned(
            bottom: 10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(widget.images.length, (dotIndex) {
                    final active = dotIndex == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _move(int delta) {
    final next = (_index + delta).clamp(0, widget.images.length - 1);
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }
}

class _CarouselArrow extends StatelessWidget {
  const _CarouselArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.34),
        foregroundColor: Colors.white,
      ),
      icon: Icon(icon),
    );
  }
}

class InfoBadge extends StatelessWidget {
  const InfoBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: _coral),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: _muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.sora(
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ContactRow extends StatelessWidget {
  const ContactRow({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _coral, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.manrope(
              color: _ink,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthProviderActions extends StatelessWidget {
  const _AuthProviderActions({
    required this.isRegister,
    required this.onGoogleTap,
  });

  final bool isRegister;
  final VoidCallback? onGoogleTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            isRegister ? 'Más formas de crear tu cuenta' : 'O continúa con',
            style: GoogleFonts.manrope(
              color: _muted,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        _AuthProviderButton(
          label: isRegister ? 'Registrarse con Google' : 'Continuar con Google',
          leading: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              'G',
              style: GoogleFonts.sora(
                color: _brandRed,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          onTap: onGoogleTap,
        ),
      ],
    );
  }
}

class _AuthProviderButton extends StatelessWidget {
  const _AuthProviderButton({
    required this.label,
    required this.leading,
    required this.onTap,
  });

  final String label;
  final Widget leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.manrope(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: _coral, size: 18),
          ],
        ),
      ),
    );
  }
}

class SocialChip extends StatelessWidget {
  const SocialChip({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, color: _coral, size: 18),
      label: Text(label),
      backgroundColor: _surface,
      side: const BorderSide(color: _line),
    );
  }
}

class CartItemCard extends StatelessWidget {
  const CartItemCard({
    super.key,
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: GoogleFonts.sora(
                          fontWeight: FontWeight.w800,
                          color: _ink,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.restaurantName,
                        style: GoogleFonts.manrope(
                          color: _muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                QuantityButton(icon: Icons.remove_rounded, onTap: onDecrease),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    item.quantity.toString(),
                    style: GoogleFonts.sora(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                QuantityButton(icon: Icons.add_rounded, onTap: onIncrease),
                const Spacer(),
                Text(
                  _currency(item.price * item.quantity),
                  style: GoogleFonts.sora(
                    fontWeight: FontWeight.w800,
                    color: _coral,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class QuantityButton extends StatelessWidget {
  const QuantityButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: _surface,
        foregroundColor: _ink,
      ),
      icon: Icon(icon),
    );
  }
}

class SummaryRow extends StatelessWidget {
  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasis = false,
  });

  final String label;
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final labelStyle = emphasis
        ? GoogleFonts.sora(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: _ink,
          )
        : GoogleFonts.manrope(fontWeight: FontWeight.w700, color: _muted);
    final valueStyle = emphasis
        ? GoogleFonts.sora(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: _coral,
          )
        : GoogleFonts.manrope(fontWeight: FontWeight.w800, color: _ink);

    return Row(
      children: [
        Text(label, style: labelStyle),
        const Spacer(),
        Text(value, style: valueStyle),
      ],
    );
  }
}

class AchievementTile extends StatelessWidget {
  const AchievementTile({super.key, required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: achievement.unlocked
              ? const Color(0xFFE5F7EB)
              : _surface,
          foregroundColor: achievement.unlocked
              ? const Color(0xFF2E9B4C)
              : _coral,
          child: Icon(
            achievement.unlocked
                ? Icons.check_rounded
                : Icons.lock_outline_rounded,
          ),
        ),
        title: Text(
          achievement.name,
          style: GoogleFonts.sora(fontWeight: FontWeight.w800, color: _ink),
        ),
        subtitle: Text(
          achievement.description,
          style: GoogleFonts.manrope(color: _muted),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: _surface,
              foregroundColor: _coral,
              child: Icon(icon, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.sora(fontWeight: FontWeight.w800, color: _ink),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(color: _muted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationOverlay extends StatelessWidget {
  const NotificationOverlay({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final latest = controller.overlayNotification;
    return Positioned(
      left: 20,
      right: 20,
      bottom: 92,
      child: IgnorePointer(
        ignoring: true,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: latest == null
              ? const SizedBox.shrink()
              : Material(
                  key: ValueKey(latest.id),
                  color: Colors.transparent,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _ink,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _notificationAccentColor(
                                latest.type,
                              ).withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              _notificationIcon(latest.type),
                              color: _notificationAccentColor(latest.type),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  latest.title,
                                  style: GoogleFonts.sora(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  latest.message,
                                  style: GoogleFonts.manrope(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

IconData _notificationIcon(AppNotificationType type) {
  switch (type) {
    case AppNotificationType.order:
      return Icons.delivery_dining_rounded;
    case AppNotificationType.social:
      return Icons.dynamic_feed_rounded;
    case AppNotificationType.restaurant:
      return Icons.storefront_rounded;
    case AppNotificationType.system:
      return Icons.notifications_active_rounded;
  }
}

Color _notificationAccentColor(AppNotificationType type) {
  switch (type) {
    case AppNotificationType.order:
      return _coral;
    case AppNotificationType.social:
      return _gold;
    case AppNotificationType.restaurant:
      return _olive;
    case AppNotificationType.system:
      return _brandRed;
  }
}

String _notificationTimeLabel(DateTime timestamp) {
  final now = DateTime.now();
  final difference = now.difference(timestamp);

  if (difference.inMinutes < 1) {
    return 'Ahora';
  }
  if (difference.inMinutes < 60) {
    return 'Hace ${difference.inMinutes} min';
  }
  if (difference.inHours < 24) {
    return 'Hace ${difference.inHours} h';
  }
  if (difference.inDays == 1) {
    return 'Ayer';
  }
  return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}';
}

String _currency(double value) {
  const copRate = 4500;
  final copValue = (value * copRate).round();
  return 'COP \$${_formatCopAmount(copValue)}';
}

String _formatCopAmount(int value) {
  final isNegative = value < 0;
  final digits = value.abs().toString();
  final parts = <String>[];

  for (var index = digits.length; index > 0; index -= 3) {
    final start = (index - 3).clamp(0, digits.length);
    parts.insert(0, digits.substring(start, index));
  }

  final formatted = parts.join('.');
  return isNegative ? '-$formatted' : formatted;
}

String _initialsFromName(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return 'LC';
  }
  if (parts.length == 1) {
    final part = parts.first;
    final end = part.length >= 2 ? 2 : 1;
    return part.substring(0, end).toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

({double progress, Color color}) _passwordStrength(String password) {
  final hasMinLength = password.length >= 8;
  final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
  final hasNumber = RegExp(r'[0-9]').hasMatch(password);
  final hasSpecialCharacter = RegExp(r'[^A-Za-z0-9]').hasMatch(password);

  if (password.isEmpty) {
    return (progress: 0.0, color: _line);
  }

  var score = 0;
  if (hasMinLength) {
    score += 1;
  }
  if (hasUppercase) {
    score += 1;
  }
  if (hasNumber) {
    score += 1;
  }
  if (hasSpecialCharacter) {
    score += 1;
  }

  if (score <= 1) {
    return (progress: 0.33, color: _coral);
  }

  if (score == 2) {
    return (progress: 0.66, color: _gold);
  }

  return (progress: 1.0, color: _olive);
}

Future<void> _showEmailVerificationSheet(
  BuildContext context, {
  required AppController controller,
  required String initialEmail,
}) async {
  final emailController = TextEditingController(text: initialEmail);
  final codeController = TextEditingController();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              24,
              16,
              16 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verifica tu correo',
                    style: GoogleFonts.sora(
                      color: _ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ingresa el codigo de 6 digitos enviado a Gmail para activar tu cuenta.',
                    style: GoogleFonts.manrope(
                      color: _muted,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(
                      'Correo electrónico',
                      Icons.alternate_email_rounded,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: _inputDecoration(
                      'Código de verificación',
                      Icons.password_rounded,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: controller.isAuthBusy
                          ? null
                          : () async {
                              final success = await controller.verifyEmailCode(
                                email: emailController.text,
                                code: codeController.text,
                              );
                              if (success && sheetContext.mounted) {
                                Navigator.of(sheetContext).pop();
                              } else {
                                setModalState(() {});
                              }
                            },
                      icon: const Icon(Icons.mark_email_read_rounded),
                      label: Text(
                        controller.isAuthBusy
                            ? 'Verificando...'
                            : 'Verificar correo',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: controller.isAuthBusy
                          ? null
                          : () async {
                              await controller.resendEmailVerificationCode(
                                email: emailController.text,
                              );
                              setModalState(() {});
                            },
                      child: const Text('Reenviar código'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  emailController.dispose();
  codeController.dispose();
}

class _EditableSavedAddress {
  _EditableSavedAddress({
    required this.id,
    required String label,
    required String address,
    required String details,
    required this.isPrimary,
  }) : labelController = TextEditingController(text: label),
       addressController = TextEditingController(text: address),
       detailsController = TextEditingController(text: details);

  factory _EditableSavedAddress.fromModel(SavedAddress address) {
    return _EditableSavedAddress(
      id: address.id,
      label: address.label,
      address: address.address,
      details: address.details,
      isPrimary: address.isPrimary,
    );
  }

  factory _EditableSavedAddress.blank(int index) {
    return _EditableSavedAddress(
      id: 'address_${DateTime.now().microsecondsSinceEpoch}_$index',
      label: 'Dirección $index',
      address: '',
      details: '',
      isPrimary: false,
    );
  }

  final String id;
  final TextEditingController labelController;
  final TextEditingController addressController;
  final TextEditingController detailsController;
  bool isPrimary;

  SavedAddress toModel() {
    return SavedAddress(
      id: id,
      label: labelController.text,
      address: addressController.text,
      details: detailsController.text,
      isPrimary: isPrimary,
    );
  }

  void dispose() {
    labelController.dispose();
    addressController.dispose();
    detailsController.dispose();
  }
}

Future<void> _showPersonalDataSheet(
  BuildContext context,
  AppController controller,
) async {
  final nameController = TextEditingController(text: controller.currentUserName);
  final phoneController = TextEditingController(text: controller.currentUserPhone);
  final addressEditors = controller.profileSavedAddresses
      .map(_EditableSavedAddress.fromModel)
      .toList();

  if (addressEditors.isEmpty) {
    addressEditors.add(
      _EditableSavedAddress(
        id: 'home',
        label: 'Casa',
        address: controller.deliveryAddress,
        details: controller.deliveryInstructions,
        isPrimary: true,
      ),
    );
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          top: 24,
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(28),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 52,
                        height: 5,
                        decoration: BoxDecoration(
                          color: _line,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Editar mis datos',
                      style: GoogleFonts.sora(
                        color: _ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cambia tu nombre, tu teléfono y todas las direcciones guardadas en un solo lugar.',
                      style: GoogleFonts.manrope(
                        color: _muted,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: nameController,
                      decoration: _inputDecoration(
                        'Nombre visible',
                        Icons.person_rounded,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration(
                        'Teléfono de contacto',
                        Icons.phone_rounded,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Direcciones guardadas',
                      style: GoogleFonts.sora(
                        color: _ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Marca una dirección principal para usarla por defecto en tus pedidos.',
                      style: GoogleFonts.manrope(
                        color: _muted,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...List.generate(addressEditors.length, (index) {
                      final entry = addressEditors[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _card,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: _line),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: entry.labelController,
                                      decoration: _inputDecoration(
                                        'Etiqueta: Casa, Trabajo...',
                                        Icons.label_rounded,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  if (entry.isPrimary)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _coral.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        'Principal',
                                        style: GoogleFonts.manrope(
                                          color: _coral,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                  else
                                    OutlinedButton(
                                      onPressed: () {
                                        setState(() {
                                          for (final item in addressEditors) {
                                            item.isPrimary = false;
                                          }
                                          entry.isPrimary = true;
                                        });
                                      },
                                      child: const Text('Principal'),
                                    ),
                                  if (addressEditors.length > 1) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          final removedPrimary = entry.isPrimary;
                                          addressEditors.removeAt(index).dispose();
                                          if (removedPrimary &&
                                              addressEditors.isNotEmpty) {
                                            addressEditors.first.isPrimary = true;
                                          }
                                        });
                                      },
                                      icon: const Icon(Icons.delete_outline_rounded),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: entry.addressController,
                                decoration: _inputDecoration(
                                  'Dirección completa',
                                  Icons.home_rounded,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: entry.detailsController,
                                minLines: 2,
                                maxLines: 3,
                                decoration: _inputDecoration(
                                  'Detalles para el repartidor',
                                  Icons.notes_rounded,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          addressEditors.add(
                            _EditableSavedAddress.blank(addressEditors.length + 1),
                          );
                        });
                      },
                      icon: const Icon(Icons.add_location_alt_rounded),
                      label: const Text('Agregar dirección'),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () async {
                        final savedAddresses = addressEditors
                            .map((entry) => entry.toModel())
                            .where((entry) => entry.address.trim().isNotEmpty)
                            .toList();
                        final primaryAddress = savedAddresses.firstWhere(
                          (entry) => entry.isPrimary,
                          orElse: () => savedAddresses.isNotEmpty
                              ? savedAddresses.first.copyWith(isPrimary: true)
                              : SavedAddress(
                                  id: 'home',
                                  label: 'Casa',
                                  address: controller.deliveryAddress,
                                  details: controller.deliveryInstructions,
                                  isPrimary: true,
                                ),
                        );

                        await controller.updateProfileBasics(
                          name: nameController.text,
                          phone: phoneController.text,
                          address: primaryAddress.address,
                          deliveryNotes: primaryAddress.details,
                          addresses: savedAddresses,
                        );
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Guardar direcciones'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );

  nameController.dispose();
  phoneController.dispose();
  for (final entry in addressEditors) {
    entry.dispose();
  }
}

Future<void> _pickProfileImage(
  BuildContext context,
  AppController controller,
) async {
  final picked = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true,
  );
  final bytes = picked?.files.single.bytes;
  if (bytes == null || bytes.isEmpty) {
    return;
  }

  try {
    final optimizedBytes = await _optimizeProfileImage(bytes);
    await controller.updateProfileImage(optimizedBytes);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil actualizada.')),
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }
}

Future<Uint8List> _optimizeProfileImage(Uint8List bytes) async {
  const maxBytes = 350 * 1024;
  if (bytes.lengthInBytes <= maxBytes) {
    return bytes;
  }

  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw Exception('No se pudo procesar la imagen seleccionada.');
  }

  var working = decoded;
  final longestSide = math.max(working.width, working.height);
  if (longestSide > 720) {
    if (working.width >= working.height) {
      working = img.copyResize(working, width: 720);
    } else {
      working = img.copyResize(working, height: 720);
    }
  }

  for (final quality in <int>[82, 74, 66, 58, 50]) {
    final encoded = Uint8List.fromList(img.encodeJpg(working, quality: quality));
    if (encoded.lengthInBytes <= maxBytes) {
      return encoded;
    }
  }

  final compact = img.copyResize(working, width: 480);
  final encoded = Uint8List.fromList(img.encodeJpg(compact, quality: 48));
  if (encoded.lengthInBytes <= maxBytes) {
    return encoded;
  }

  throw Exception('La imagen es demasiado pesada incluso después de optimizarla. Usa una foto más liviana.');
}

InputDecoration _inputDecoration(String hint, IconData icon) {
  return InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.manrope(color: _muted),
    prefixIcon: Icon(icon, color: _coral),
    filled: true,
    fillColor: _card,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: const BorderSide(color: _line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: const BorderSide(color: _line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: const BorderSide(color: _coral, width: 1.2),
    ),
  );
}

IconData _paymentMethodIcon(PaymentMethodType type) {
  switch (type) {
    case PaymentMethodType.card:
      return Icons.credit_card_rounded;
    case PaymentMethodType.cash:
      return Icons.payments_rounded;
    case PaymentMethodType.wallet:
      return Icons.account_balance_wallet_rounded;
    case PaymentMethodType.instant:
      return Icons.bolt_rounded;
    case PaymentMethodType.nequi:
      return Icons.phone_android_rounded;
    case PaymentMethodType.bankTransfer:
      return Icons.account_balance_rounded;
  }
}

String _date(DateTime value) {
  const months = <String>[
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  return '${value.day} ${months[value.month - 1]} · ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

String _paymentMethodLabel(PaymentMethodType type) {
  switch (type) {
    case PaymentMethodType.card:
      return 'Tarjeta';
    case PaymentMethodType.cash:
      return 'Efectivo';
    case PaymentMethodType.wallet:
      return 'Billetera';
    case PaymentMethodType.instant:
      return 'Transferencia';
    case PaymentMethodType.nequi:
      return 'Nequi';
    case PaymentMethodType.bankTransfer:
      return 'Transferencia bancaria';
  }
}

String _orderStatusLabel(OrderStatus status) {
  switch (status) {
    case OrderStatus.confirmed:
      return 'Confirmado';
    case OrderStatus.preparing:
      return 'Preparando';
    case OrderStatus.onTheWay:
      return 'En camino';
    case OrderStatus.delivered:
      return 'Entregado';
  }
}

Color _orderStatusColor(OrderStatus status) {
  switch (status) {
    case OrderStatus.confirmed:
      return _coral;
    case OrderStatus.preparing:
      return _gold;
    case OrderStatus.onTheWay:
      return _olive;
    case OrderStatus.delivered:
      return const Color(0xFF2E7D32);
  }
}

Color _orderStatusBackground(OrderStatus status) {
  switch (status) {
    case OrderStatus.confirmed:
      return _coral.withValues(alpha: 0.12);
    case OrderStatus.preparing:
      return _gold.withValues(alpha: 0.18);
    case OrderStatus.onTheWay:
      return _olive.withValues(alpha: 0.14);
    case OrderStatus.delivered:
      return const Color(0xFF2E7D32).withValues(alpha: 0.12);
  }
}

class _OrderStatusChip extends StatelessWidget {
  const _OrderStatusChip({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _orderStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _orderStatusBackground(status),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _orderStatusLabel(status),
        style: GoogleFonts.manrope(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
