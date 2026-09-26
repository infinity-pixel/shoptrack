// Prints data for lib/core/calendar/umm_al_qura_data.dart; does not write files.
// Reference runtime: Node 20.17.0 / ICU 75.1. Different ICU versions must be
// reviewed for calendar-data changes before replacing the shipped table.
const formatter = new Intl.DateTimeFormat('en-u-ca-islamic-umalqura', {
  day: 'numeric', month: 'numeric', year: 'numeric', timeZone: 'UTC',
});
const masks = Array(301).fill(0);
let months = 0;
for (let time = Date.UTC(1882, 10, 12); time <= Date.UTC(2174, 11, 1); time += 86400000) {
  const fields = Object.fromEntries(formatter.formatToParts(new Date(time)).map(p => [p.type, p.value]));
  const year = Number(fields.year), month = Number(fields.month), day = Number(fields.day);
  if (year > 1600) break;
  if (day === 1) months++;
  if (day === 30) masks[year - 1300] |= 1 << (12 - month);
}
if (months !== 3612) throw Error(`Unexpected calendar range: ${months} months`);
console.log(`// Generated with Node ${process.version}, ICU ${process.versions.icu}`);
console.log(`const ummAlQuraMonthMasks = <int>[${masks.join(', ')}];`);
