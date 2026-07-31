import { StatusBar } from 'expo-status-bar';
import { SafeAreaView, ScrollView, StyleSheet, Text, View } from 'react-native';

// Proof that Metro resolves @lacasa/domain from apps/mobile: LEAD_STATUS is
// imported straight from the package's `./enums/leads` subpath export, and
// formatCreatedAt from `./formatting/date` — the same shared enum and date
// formatter apps/web's LeadKanbanList and apps/api's serializers use, now
// running unmodified on React Native.
import { LEAD_STATUS, type LeadStatusKey } from '@lacasa/domain/enums/leads';
import { formatCreatedAt } from '@lacasa/domain/formatting/date';

const STATUS_LABELS: Record<LeadStatusKey, string> = {
  new: 'New',
  could_not_connect: 'Could not connect',
  need_to_call_back: 'Need to call back',
  rejected: 'Rejected',
  accepted: 'Accepted',
};

const now = formatCreatedAt(new Date());

export function LeadStatusProofScreen() {
  return (
    <SafeAreaView style={styles.safeArea}>
      <StatusBar style="auto" />
      <ScrollView contentContainerStyle={styles.content}>
        <Text style={styles.eyebrow}>@lacasa/mobile</Text>
        <Text style={styles.title}>Lead statuses</Text>
        <Text style={styles.subtitle}>
          Rendered from @lacasa/domain&apos;s LEAD_STATUS enum and
          formatCreatedAt — resolved by Metro from the shared workspace
          package, unmodified.
        </Text>

        <View style={styles.list}>
          {(Object.keys(LEAD_STATUS) as LeadStatusKey[]).map((key) => (
            <View key={key} style={styles.row}>
              <Text style={styles.rowLabel}>{STATUS_LABELS[key]}</Text>
              <Text style={styles.rowValue}>{LEAD_STATUS[key]}</Text>
            </View>
          ))}
        </View>

        <Text style={styles.footer}>Loaded {now}</Text>
      </ScrollView>
    </SafeAreaView>
  );
}

// Neutral, cross-platform styling on purpose: no iOS system fonts/blur, no
// Material elevation/ripple — plain colors and spacing that read the same
// on iOS, Android, and web.
const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: '#F5F5F5',
  },
  content: {
    padding: 24,
    gap: 8,
  },
  eyebrow: {
    fontSize: 13,
    fontWeight: '600',
    letterSpacing: 0.5,
    color: '#6B7280',
    textTransform: 'uppercase',
  },
  title: {
    fontSize: 28,
    fontWeight: '700',
    color: '#111827',
  },
  subtitle: {
    fontSize: 14,
    lineHeight: 20,
    color: '#4B5563',
    marginBottom: 16,
  },
  list: {
    borderWidth: 1,
    borderColor: '#E5E7EB',
    borderRadius: 12,
    overflow: 'hidden',
  },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
    backgroundColor: '#FFFFFF',
  },
  rowLabel: {
    fontSize: 15,
    color: '#111827',
  },
  rowValue: {
    fontSize: 13,
    fontFamily: 'monospace',
    color: '#6B7280',
  },
  footer: {
    marginTop: 16,
    fontSize: 12,
    color: '#9CA3AF',
  },
});
