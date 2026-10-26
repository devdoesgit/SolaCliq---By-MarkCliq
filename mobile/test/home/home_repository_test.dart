import 'package:api_client/api_client.dart' show HomeApi;
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/home/data/home_repository.dart';

import '../helpers/helpers.dart';

void main() {
  test('maps every part of the server-composed home', () async {
    late RequestOptions sent;
    final dio = Dio(BaseOptions(baseUrl: 'http://api'))
      ..httpClientAdapter = FakeAdapter((o) async {
        sent = o;
        return jsonBody(200, {
          'eyebrow': 'Your solar',
          'title': '5 kW',
          'headline': {'value': '1', 'label': 'of 7 stages'},
          'week': [
            {
              'day': 'Thu',
              'date': 23,
              'today': true,
              'dots': ['done', 'live', 'planned'],
            },
          ],
          'energy': {
            'now_kw': 3.8,
            'today_kwh': 18,
            'sunrise': '06:12',
            'sunset': '17:41',
            'day_progress': 0.5,
            'hours': [0, 1.5],
            'now_index': 1,
          },
          'tiles': [
            {
              'label': 'Saved',
              'value': '₹4k',
              'icon': 'wallet',
              'dark': true,
              'avatars': [
                {'glyph': 'rupee'},
              ],
              'action': 'savings',
            },
          ],
          'progress': {
            'label': 'KYC',
            'segments': [
              {'weight': 2, 'tone': 'success', 'label': '2 done'},
              {'weight': 1, 'tone': 'empty'},
            ],
            'legend': true,
          },
          'list': {
            'title': 'Recent',
            'rows': [
              {
                'id': 'r1',
                'initials': 'SR',
                'title': 'Row',
                'detail': 'Detail',
                'status': {'label': 'Fix', 'tone': 'danger'},
              },
            ],
          },
        });
      });
    final home = await HomeRepository(HomeApi(dio))
        .orgHome('o1', OrgRole.agent);

    expect(sent.path, '/orgs/o1/home');
    expect(sent.extra[HomeRepository.mockExampleKey], 'agent');
    expect(home.headline!.label, 'of 7 stages');
    expect(home.week.single.dots, [
      HomeDot.done,
      HomeDot.live,
      HomeDot.planned,
    ]);
    expect(home.energy!.todayKwh, 18.0);
    expect(home.energy!.hours, [0.0, 1.5]);
    expect(home.tiles.single.icon, HomeIcon.wallet);
    expect(home.tiles.single.avatars.single.glyph, HomeGlyph.rupee);
    expect(home.progress!.segments.last.tone, HomeTone.empty);
    expect(home.progress!.legend, isTrue);
    expect(home.listTitle, 'Recent');
    expect(home.rows.single.status!.tone, HomeTone.danger);
    expect(home.rows.single.visual.initials, 'SR');
  });
}
