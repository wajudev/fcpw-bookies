import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/match_model.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';

class PredictionDialog extends StatefulWidget {
  final Match match;
  final Prediction? existingPrediction;

  const PredictionDialog({
    super.key,
    required this.match,
    this.existingPrediction,
  });

  @override
  State<PredictionDialog> createState() => _PredictionDialogState();
}

class _PredictionDialogState extends State<PredictionDialog> {
  late TextEditingController _homeController;
  late TextEditingController _awayController;
  final _formKey = GlobalKey<FormState>();
  final bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _homeController = TextEditingController(
      text: widget.existingPrediction?.homeScoreGuess.toString() ?? '',
    );
    _awayController = TextEditingController(
      text: widget.existingPrediction?.awayScoreGuess.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _homeController.dispose();
    _awayController.dispose();
    super.dispose();
  }

  void _submit() {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final homeScore = int.parse(_homeController.text);
    final awayScore = int.parse(_awayController.text);

    // Already validated, this shouldn't happen
    if (homeScore < 0 || homeScore > 99 || awayScore < 0 || awayScore > 99) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte gültige Zahlen eingeben'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (homeScore < 0 || awayScore < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ergebnis muss positiv sein'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.of(context).pop({
      'homeScore': homeScore,
      'awayScore': awayScore,
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, d MMM · HH:mm', 'de_DE');
    final isLocked = widget.match.isLocked;
    final isFinished = widget.match.status == MatchStatus.finished;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    isFinished
                        ? 'Ergebnis'
                        : isLocked
                            ? 'Tipp gesperrt'
                            : widget.existingPrediction != null
                                ? 'Tipp bearbeiten'
                                : 'Make Prediction',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              dateFormat.format(widget.match.kickoffTime),
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Teams and scores
            Row(
              children: [
                // Home team
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        widget.match.homeTeam,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      if (isFinished)
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '${widget.match.homeScoreActual ?? 0}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isLocked
                                ? Colors.grey.shade100
                                : AppTheme.primaryPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isLocked
                                  ? Colors.grey.shade300
                                  : AppTheme.primaryPurple,
                              width: 2,
                            ),
                          ),
                          child: TextFormField(
                            controller: _homeController,
                            enabled: !isLocked,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            validator: Validators.scoreValidator,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: isLocked
                                  ? Colors.grey.shade400
                                  : AppTheme.primaryPurple,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              errorStyle: TextStyle(fontSize: 10, height: 0.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // VS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    ':',
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),

                // Away team
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        widget.match.awayTeam,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      if (isFinished)
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '${widget.match.awayScoreActual ?? 0}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isLocked
                                ? Colors.grey.shade100
                                : AppTheme.primaryPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isLocked
                                  ? Colors.grey.shade300
                                  : AppTheme.primaryPurple,
                              width: 2,
                            ),
                          ),
                          child: TextFormField(
                            controller: _awayController,
                            enabled: !isLocked,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            validator: Validators.scoreValidator,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: isLocked
                                  ? Colors.grey.shade400
                                  : AppTheme.primaryPurple,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              errorStyle: TextStyle(fontSize: 10, height: 0.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Existing prediction info
            if (widget.existingPrediction != null && !isFinished) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Aktueller Tipp: ${widget.existingPrediction!.homeScoreGuess}:${widget.existingPrediction!.awayScoreGuess}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Points awarded (for finished matches)
            if (isFinished && widget.existingPrediction?.pointsAwarded != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getPointsColor(widget.existingPrediction!.pointsAwarded!)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.existingPrediction!.pointsAwarded == 3
                          ? Icons.star
                          : widget.existingPrediction!.pointsAwarded == 1
                              ? Icons.check_circle
                              : Icons.close,
                      size: 20,
                      color: _getPointsColor(widget.existingPrediction!.pointsAwarded!),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.existingPrediction!.pointsAwarded} Punkte',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getPointsColor(widget.existingPrediction!.pointsAwarded!),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Lock warning
            if (isLocked && !isFinished)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tipp ist 2 Stunden vor Anpfiff gesperrt',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (!isLocked && !isFinished) ...[
              const SizedBox(height: 8),
              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          widget.existingPrediction != null
                              ? 'Tipp aktualisieren'
                              : 'Make Prediction',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ],
          ),
        ),
      ),
    );
  }

  Color _getPointsColor(int points) {
    if (points == 3) return AppTheme.primaryGreen;
    if (points == 1) return AppTheme.kmGold;
    return AppTheme.liveRed;
  }
}
