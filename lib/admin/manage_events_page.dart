import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../services/firebase_service.dart';
import '../models/event_model.dart';

class ManageEventsPage extends StatelessWidget {
  const ManageEventsPage({super.key});

  void _showEventDialog(BuildContext context, {EventModel? event}) {
    showDialog(
      context: context,
      builder: (context) => _EventDialog(event: event),
    );
  }

  void _deleteEvent(BuildContext context, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Delete Event', style: GoogleFonts.outfit(color: AppColors.textPrimary)),
        content: Text('Are you sure you want to delete this event?', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseService().deleteEvent(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Manage Events',
                              style: GoogleFonts.outfit(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              )),
                          Text('Global announcements and activities',
                              style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: StreamBuilder<List<EventModel>>(
                  stream: FirebaseService().getEventsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                    }
                    final events = snapshot.data ?? [];
                    if (events.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.event_busy_rounded, size: 64, color: AppColors.textMuted),
                            const SizedBox(height: 16),
                            Text('No events scheduled',
                                style: GoogleFonts.outfit(color: AppColors.textSecondary)),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => _showEventDialog(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Create Event'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            )
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return _EventCard(
                          event: event,
                          onEdit: () => _showEventDialog(context, event: event),
                          onDelete: () => _deleteEvent(context, event.id),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEventDialog(context),
        label: const Text('Add Event'),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EventCard({required this.event, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                event.imageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 150,
                  color: AppColors.textMuted.withOpacity(0.1),
                  child: const Icon(Icons.image_not_supported_rounded),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.name,
                          style: GoogleFonts.outfit(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(DateFormat('MMM dd, yyyy').format(event.date),
                              style: GoogleFonts.outfit(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(event.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(icon: const Icon(Icons.edit_rounded, size: 20, color: AppColors.textSecondary), onPressed: onEdit),
                    IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent), onPressed: onDelete),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventDialog extends StatefulWidget {
  final EventModel? event;
  const _EventDialog({this.event});

  @override
  State<_EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<_EventDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  File? _imageFile;
  bool _isLoading = false;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _nameController.text = widget.event!.name;
      _descController.text = widget.event!.description;
      _selectedDate = widget.event!.date;
      _existingImageUrl = widget.event!.imageUrl;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty || _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? imageUrl = _existingImageUrl;
      if (_imageFile != null) {
        imageUrl = await FirebaseService().uploadEventImage(_imageFile!);
      }

      final event = EventModel(
        id: widget.event?.id ?? '',
        name: _nameController.text,
        description: _descController.text,
        date: _selectedDate,
        imageUrl: imageUrl,
        createdAt: widget.event?.createdAt ?? DateTime.now(),
      );

      await FirebaseService().saveEvent(event);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.event == null ? 'Create Event' : 'Edit Event',
                style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            
            // Image Picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: _imageFile != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(_imageFile!, fit: BoxFit.cover))
                    : _existingImageUrl != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(_existingImageUrl!, fit: BoxFit.cover))
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_a_photo_rounded, color: AppColors.textSecondary),
                              const SizedBox(height: 8),
                              Text('Add Event Picture', style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _nameController,
              style: GoogleFonts.outfit(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Event Name',
                labelStyle: GoogleFonts.outfit(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.textMuted.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 3,
              style: GoogleFonts.outfit(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: GoogleFonts.outfit(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.textMuted.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            
            // Date Picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Event Date', style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13)),
              subtitle: Text(DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate),
                  style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.date_range_rounded, color: AppColors.primary),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
            ),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Event'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
