import 'package:api_client/api_client.dart' as api;
import 'package:equatable/equatable.dart';
import 'package:solacliq/app/data/api_call.dart';
import 'package:uuid/uuid.dart';

enum QuoteFor { home, business, farm }

enum BillBand { under1500, from1500To3000, from3000To6000, over6000 }

enum RoofType { rcc, tinShed, other }

enum QuoteTimeline { thisMonth, in1To3Months, exploring }

/// The indicative estimate returned with a quote request. Money in paise.
class QuoteEstimate extends Equatable {
  const new({
    required this.kwMin,
    required this.kwMax,
    required this.priceMin,
    required this.priceMax,
    required this.subsidyMax,
  });

  final num kwMin;
  final num kwMax;
  final int priceMin;
  final int priceMax;
  final int subsidyMax;

  @override
  List<Object> get props => [kwMin, kwMax, priceMin, priceMax, subsidyMax];
}

/// Quote requests: leads that verified companies nearby can accept.
class QuoteRepository {
  new(this._api);

  final api.QuotesApi _api;
  static const _uuid = Uuid();

  Future<QuoteEstimate> request({
    required QuoteFor quoteFor,
    required String pinCode,
    required String city,
    required BillBand billBand,
    required RoofType roof,
    required QuoteTimeline timeline,
    String? phone,
  }) async {
    final response = await apiCall(
      () => _api.createQuoteRequest(
        idempotencyKey: _uuid.v4(),
        quoteRequestCreate: api.QuoteRequestCreate(
          quoteFor: switch (quoteFor) {
            QuoteFor.home => api.QuoteFor.home,
            QuoteFor.business => api.QuoteFor.business,
            QuoteFor.farm => api.QuoteFor.farm,
          },
          pinCode: pinCode,
          city: city,
          billBand: switch (billBand) {
            BillBand.under1500 => api.BillBand.under1500,
            BillBand.from1500To3000 => api.BillBand.from1500To3000,
            BillBand.from3000To6000 => api.BillBand.from3000To6000,
            BillBand.over6000 => api.BillBand.over6000,
          },
          roof: switch (roof) {
            RoofType.rcc => api.RoofType.rcc,
            RoofType.tinShed => api.RoofType.tinShed,
            RoofType.other => api.RoofType.other,
          },
          timeline: switch (timeline) {
            QuoteTimeline.thisMonth => api.QuoteTimeline.thisMonth,
            QuoteTimeline.in1To3Months => api.QuoteTimeline.in1To3Months,
            QuoteTimeline.exploring => api.QuoteTimeline.exploring,
          },
          phone: phone,
          shareConsent: true,
        ),
      ),
    );
    final e = response.data!.estimate;
    return QuoteEstimate(
      kwMin: e.kwMin,
      kwMax: e.kwMax,
      priceMin: e.priceMin,
      priceMax: e.priceMax,
      subsidyMax: e.subsidyMax,
    );
  }
}
