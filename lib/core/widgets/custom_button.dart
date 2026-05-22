import 'package:flutter/material.dart';

enum ButtonVariant { primary, secondary }

enum ButtonSize { small, medium, large }

class CustomButton extends StatefulWidget {
  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final Widget? icon;
  final double? width;

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _pressed = false;

  bool get _disabled => widget.onPressed == null || widget.isLoading;

  _SizeConfig get _sizeConfig => switch (widget.size) {
    ButtonSize.small => const _SizeConfig(v: 10, h: 16, fs: 13, iconSize: 16),
    ButtonSize.medium => const _SizeConfig(v: 14, h: 24, fs: 15, iconSize: 18),
    ButtonSize.large => const _SizeConfig(v: 16, h: 28, fs: 16, iconSize: 20),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _sizeConfig;
    final isPrimary = widget.variant == ButtonVariant.primary;

    return GestureDetector(
      onTapDown: _disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: _disabled
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onPressed?.call();
            },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: SizedBox(
          width: widget.width,
          child: isPrimary
              ? _PrimaryButton(cfg: cfg, widget: widget, disabled: _disabled)
              : _SecondaryButton(cfg: cfg, widget: widget, disabled: _disabled),
        ),
      ),
    );
  }
}

// ── Primary ───────────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.cfg,
    required this.widget,
    required this.disabled,
  });
  final _SizeConfig cfg;
  final CustomButton widget;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        gradient: disabled
            ? null
            : const LinearGradient(
                colors: [Color(0xFF2D7A4F), Color(0xFF48C78A)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        color: disabled ? const Color(0xFFC8E2D0) : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: disabled
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF2D7A4F).withOpacity(0.30),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: cfg.v, horizontal: cfg.h),
        child: _ButtonContent(
          cfg: cfg,
          widget: widget,
          disabled: disabled,
          isPrimary: true,
        ),
      ),
    );
  }
}

// ── Secondary ─────────────────────────────────────────────────────────────────

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.cfg,
    required this.widget,
    required this.disabled,
  });
  final _SizeConfig cfg;
  final CustomButton widget;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final borderColor = disabled
        ? const Color(0xFF9AB5A5)
        : const Color(0xFF2D7A4F);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: cfg.v, horizontal: cfg.h),
        child: _ButtonContent(
          cfg: cfg,
          widget: widget,
          disabled: disabled,
          isPrimary: false,
        ),
      ),
    );
  }
}

// ── Content ───────────────────────────────────────────────────────────────────

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.cfg,
    required this.widget,
    required this.disabled,
    required this.isPrimary,
  });
  final _SizeConfig cfg;
  final CustomButton widget;
  final bool disabled;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final textColor = disabled
        ? const Color(0xFF9AB5A5)
        : (isPrimary ? Colors.white : const Color(0xFF2D7A4F));

    if (widget.isLoading) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isPrimary ? Colors.white : const Color(0xFF2D7A4F),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: cfg.fs,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          IconTheme(
            data: IconThemeData(color: textColor, size: cfg.iconSize),
            child: widget.icon!,
          ),
          const SizedBox(width: 8),
        ],
        Text(
          widget.label,
          style: TextStyle(
            fontSize: cfg.fs,
            fontWeight: FontWeight.w700,
            color: textColor,
            height: 1,
          ),
        ),
      ],
    );
  }
}

// ── Config ────────────────────────────────────────────────────────────────────

class _SizeConfig {
  const _SizeConfig({
    required this.v,
    required this.h,
    required this.fs,
    required this.iconSize,
  });
  final double v;
  final double h;
  final double fs;
  final double iconSize;
}
