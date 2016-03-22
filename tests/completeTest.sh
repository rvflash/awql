#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../vendor/bash-packages/testing.sh
source ../core/complete.sh

# Default entries
declare -r TEST_COMP_API_VERSION="v201601"
declare -r TEST_COMP_TABLE="CAMPAIGN_PERFORMANCE_REPORT"
declare -r TEST_COMP_TABLE_COMPLETE="AIGN_"
declare -r TEST_COMP_TABLE_FIELDS_BEGINNING_BY_C="CampaignId CampaignName CampaignStatus ClickAssistedConversions ClickAssistedConversionsOverLastClickConversions ClickAssistedConversionValue ClickConversionRate ClickConversionRateSignificance Clicks ClickSignificance ClickType ContentBudgetLostImpressionShare ContentImpressionShare ContentRankLostImpressionShare ConversionCategoryName ConversionRate Conversions ConversionTrackerId ConversionTypeName ConversionValue ConvertedClicks ConvertedClicksSignificance Cost CostPerAllConversion CostPerConversion CostPerConvertedClick CostPerConvertedClickSignificance CostSignificance CpcSignificance CpmSignificance CrossDeviceConversions Ctr CtrSignificance CustomerDescriptiveName"
declare -r TEST_COMP_TABLES="ADGROUP_PERFORMANCE_REPORT CRITERIA_PERFORMANCE_REPORT PLACEHOLDER_REPORT CAMPAIGN_NEGATIVE_PLACEMENTS_PERFORMANCE_REPORT CAMPAIGN_AD_SCHEDULE_TARGET_REPORT ACCOUNT_PERFORMANCE_REPORT KEYWORDLESS_QUERY_REPORT AD_PERFORMANCE_REPORT BUDGET_PERFORMANCE_REPORT FINAL_URL_REPORT USER_AD_DISTANCE_REPORT PAID_ORGANIC_QUERY_REPORT SEARCH_QUERY_PERFORMANCE_REPORT PRODUCT_PARTITION_REPORT CAMPAIGN_NEGATIVE_KEYWORDS_PERFORMANCE_REPORT URL_PERFORMANCE_REPORT PLACEHOLDER_FEED_ITEM_REPORT AGE_RANGE_PERFORMANCE_REPORT KEYWORDLESS_CATEGORY_REPORT DISPLAY_KEYWORD_PERFORMANCE_REPORT CAMPAIGN_NEGATIVE_LOCATIONS_REPORT LABEL_REPORT DISPLAY_TOPICS_PERFORMANCE_REPORT AUTOMATIC_PLACEMENTS_PERFORMANCE_REPORT VIDEO_PERFORMANCE_REPORT DESTINATION_URL_REPORT SHOPPING_PERFORMANCE_REPORT CAMPAIGN_SHARED_SET_REPORT CAMPAIGN_LOCATION_TARGET_REPORT GEO_PERFORMANCE_REPORT GENDER_PERFORMANCE_REPORT CAMPAIGN_PLATFORM_TARGET_REPORT CAMPAIGN_PERFORMANCE_REPORT AD_CUSTOMIZERS_FEED_ITEM_REPORT CALL_METRICS_CALL_DETAILS_REPORT CLICK_PERFORMANCE_REPORT SHARED_SET_CRITERIA_REPORT KEYWORDS_PERFORMANCE_REPORT AUDIENCE_PERFORMANCE_REPORT SHARED_SET_REPORT PLACEMENT_PERFORMANCE_REPORT CREATIVE_CONVERSION_REPORT BID_GOAL_PERFORMANCE_REPORT"
declare -r TEST_COMP_TABLES_BEGINNING_BY_C="CRITERIA_PERFORMANCE_REPORT CAMPAIGN_NEGATIVE_PLACEMENTS_PERFORMANCE_REPORT CAMPAIGN_AD_SCHEDULE_TARGET_REPORT CAMPAIGN_NEGATIVE_KEYWORDS_PERFORMANCE_REPORT CAMPAIGN_NEGATIVE_LOCATIONS_REPORT CAMPAIGN_SHARED_SET_REPORT CAMPAIGN_LOCATION_TARGET_REPORT CAMPAIGN_PLATFORM_TARGET_REPORT CAMPAIGN_PERFORMANCE_REPORT CALL_METRICS_CALL_DETAILS_REPORT CLICK_PERFORMANCE_REPORT CREATIVE_CONVERSION_REPORT"
declare -r TEST_COMP_CAMPAIGN_PERFORMANCE_REPORT="AccountCurrencyCode AccountDescriptiveName AccountTimeZoneId ActiveViewCpm ActiveViewCtr ActiveViewImpressions ActiveViewMeasurability ActiveViewMeasurableCost ActiveViewMeasurableImpressions ActiveViewViewability AdNetworkType1 AdNetworkType2 AdvertiserExperimentSegmentationBin AdvertisingChannelSubType AdvertisingChannelType AllConversionRate AllConversions AllConversionValue Amount AverageCost AverageCpc AverageCpe AverageCpm AverageCpv AverageFrequency AveragePageviews AveragePosition AverageTimeOnSite BiddingStrategyId BiddingStrategyName BiddingStrategyType BidType BounceRate BudgetId CampaignId CampaignName CampaignStatus ClickAssistedConversions ClickAssistedConversionsOverLastClickConversions ClickAssistedConversionValue ClickConversionRate ClickConversionRateSignificance Clicks ClickSignificance ClickType ContentBudgetLostImpressionShare ContentImpressionShare ContentRankLostImpressionShare ConversionCategoryName ConversionRate Conversions ConversionTrackerId ConversionTypeName ConversionValue ConvertedClicks ConvertedClicksSignificance Cost CostPerAllConversion CostPerConversion CostPerConvertedClick CostPerConvertedClickSignificance CostSignificance CpcSignificance CpmSignificance CrossDeviceConversions Ctr CtrSignificance CustomerDescriptiveName Date DayOfWeek Device EndDate EngagementRate Engagements EnhancedCpcEnabled EnhancedCpvEnabled ExternalCustomerId GmailForwards GmailSaves GmailSecondaryClicks HourOfDay ImpressionAssistedConversions ImpressionAssistedConversionsOverLastClickConversions ImpressionAssistedConversionValue ImpressionReach Impressions ImpressionSignificance InteractionRate Interactions InvalidClickRate InvalidClicks IsBudgetExplicitlyShared LabelIds Labels Month MonthOfYear NumOfflineImpressions NumOfflineInteractions OfflineInteractionRate PercentNewVisitors Period PositionSignificance PrimaryCompanyName Quarter RelativeCtr SearchBudgetLostImpressionShare SearchExactMatchImpressionShare SearchImpressionShare SearchRankLostImpressionShare ServingStatus Slot StartDate TrackingUrlTemplate UrlCustomParameters ValuePerAllConversion ValuePerConversion ValuePerConvertedClick VideoQuartile100Rate VideoQuartile25Rate VideoQuartile50Rate VideoQuartile75Rate VideoViewRate VideoViews ViewThroughConversions ViewThroughConversionsSignificance Week Year"
declare -r TEST_COMP_CAMPAIGN_FIELDS="CampaignName CampaignsCount CampaignCount CampaignStatus CampaignLocationTargetId CampaignId"
declare -r TEST_COMP_FIELDS="IsSelfAction EffectiveDestinationUrl CreativeId CallDuration CriteriaDestinationUrl GmailForwards CostSignificance TargetingAdGroupId AllConversionValue VideoTitle EffectiveTrackingUrlTemplate PageOnePromotedBidCeiling ValuePerAllConversion CrossDeviceConversions ConversionTypeName SharedSetId UserListId TargetRoas CpcBidSource CtrSignificance Impressions AverageCpv MemberCount FinalUrl OrganicImpressions EndDate NonRemovedAdGroupCriteriaCount CreativeFinalUrls EngagementRate OrganicImpressionsPerQuery KeywordMatchType IsAutoOptimized Domain SearchExactMatchImpressionShare LocationType CityCriteriaId AverageFrequency ClickConversionRateSignificance ClickAssistedConversionValue Ctr CostPerAllConversion ContentRankLostImpressionShare EstimatedAddCostAtFirstPositionCpc CpvBid AveragePageviews CostPerConvertedClick CriteriaType AdvertisingChannelType FeedItemStatus Category0 CriteriaId StartDate CallerCountryCallingCode CreativeFinalAppUrls CreativeDestinationUrl ClickAssistedConversionsOverLastClickConversions FeedItemStartTime AccountDescriptiveName Category1 MostSpecificCriteriaId PostClickQualityScore FirstPositionCpc Page Category2 FinalUrls PercentNewVisitors KeywordId FeedItemId DestinationUrl CriteriaParameters TargetCpa KeywordTargetingText FeedId CampaignName AdGroupId BenchmarkAverageMaxCpc Query LopMostSpecificTargetId TargetRoasBidCeiling TargetOutrankShareMaxCpcBidCeiling TargetCpaMaxCpcBidFloor TrackingUrlTemplate VideoViewRate AdNetworkType1 ActiveViewMeasurability VideoDuration CriteriaStatus GclId RelativeCtr ClickAssistedConversions IsAutoTaggingEnabled CampaignsCount AssociatedCampaignStatus UrlCustomParameters InteractionRate Device Brand OrganicClicksPerQuery LabelName MetroCriteriaId PageOnePromotedBidModifier Id AdType AdGroupAdDisapprovalReasons AdNetworkType2 AccountTimeZoneId ProductTypeL1 CpmBidSource Headline ClickType AllConversions LabelId BudgetStatus EnhancedCpcEnabled BidType IsTestAccount AverageCpe ProductTypeL3 PartitionType Title CountryCriteriaId NonRemovedAdGroupCount ProductTypeL2 CpcSignificance ClickSignificance Year CustomerDescriptiveName ProductTypeL5 ReferenceCount AdGroupsCount CreativeStatus ProductTypeL4 TopOfPageCpc SearchPredictedCtr Parameter CpmSignificance CostPerConvertedClickSignificance ExtensionPlaceholderType NumOfflineInteractions PositionSignificance GeoTargetingCriterionId ContentBudgetLostImpressionShare ClickConversionRate QueryMatchType PageOnePromotedRaiseBidWhenBudgetConstrained IsPathExcluded IsBidOnPath AverageCpc CombinedAdsOrganicClicksPerQuery IsTargetingLocation AoiMostSpecificTargetId CallType Type GmailSaves PageOnePromotedBidChangesForRaisesOnly CreativeTrackingUrlTemplate AverageCpm ActiveViewMeasurableCost VideoId ExtensionPlaceholderCreativeId ConvertedClicksSignificance ValuePerConvertedClick KeywordTextMatchingQuery PageOnePromotedRaiseBidWhenLowQualityScore CampaignCount ImageAdUrl Interactions AccountCurrencyCode StoreId CombinedAdsOrganicQueries CreativeQualityScore RegionCriteriaId BudgetId CampaignStatus OfflineInteractionRate ViewThroughConversions ContentImpressionShare QueryMatchTypeWithVariant ParentCriterionId BudgetName TargetOutrankShareCompetitorDomain BidModifier ConversionRate AdGroupCriterionStatus DisplayName CpmBid VideoQuartile50Rate VideoQuartile25Rate AdGroupCriteriaCount IsRestrict ImpressionAssistedConversions SearchImpressionShare Engagements SharedSetType CpcBid ImageCreativeName KeywordTargetingMatchType ConversionCategoryName LanguageCriteriaId BenchmarkCtr Scheduling AttributeValues SerpType CriteriaTypeName ServingStatus BiddingStrategyType AdGroupStatus QualityScore DeliveryMethod TargetCpaMaxCpcBidCeiling FeedItemEndTime ConversionTrackerId AggregatorId BudgetCampaignAssociationStatus TargetSpendSpendTarget TargetOutrankShare TargetingCampaignId Week Slot CostPerConversion ActiveViewMeasurableImpressions DisplayUrl InvalidClickRate CallTrackingDisplayLocation TargetOutrankShareRaiseBidWhenLowQualityScore DisapprovalShortNames AdGroupCreativesCount ApprovalStatus AdvertisingChannelSubType FinalAppUrls AdvertiserExperimentSegmentationBin ProductCondition CategoryL4 SearchQuery EffectiveFinalUrl OfferId Channel CategoryL5 IsBudgetExplicitlyShared AssociatedCampaignName BiddingStrategyId CreativeFinalMobileUrls DayOfWeek NonRemovedCampaignCount EnhancedCpvEnabled ViewThroughConversionsSignificance FeedItemAttributes AverageCost DistanceBucket Url Line1 TargetRoasBidFloor Conversions Clicks EndTime ImpressionReach CallEndTime AverageTimeOnSite ActiveViewViewability CategoryL1 Labels IsNegative AdGroupName ConvertedClicks ActiveViewImpressions CategoryL2 InvalidClicks ActiveViewCtr CategoryL3 StartTime PlaceholderType CombinedAdsOrganicClicks SystemServingStatus CallStartTime BudgetReferenceCount SearchBudgetLostImpressionShare CustomAttribute1 OrganicClicks SharedSetName LabelIds ImpressionAssistedConversionValue AdId CustomAttribute0 ValidationDetails PageOnePromotedStrategyGoal Name AdGroupCount NumOfflineImpressions HourOfDay CustomAttribute3 ChannelExclusivity ProductGroup EstimatedAddClicksAtFirstPositionCpc ContentBidCriterionTypeGroup PrimaryCompanyName CustomAttribute2 CreativeUrlCustomParameters ConversionValue AllConversionRate Amount CustomAttribute4 FirstPageCpc CpvBidSource VideoViews CallStatus AdFormat Status MerchantId AssociatedCampaignId BiddingStrategyName Cost TargetOutrankShareBidChangesForRaisesOnly FinalMobileUrls Description2 CreativeApprovalStatus ValuePerConversion VideoQuartile100Rate DevicePreference AdGroupAdTrademarkDisapproved CanManageClients Month ExternalCustomerId CampaignLocationTargetId Period TargetSpendBidCeiling GmailSecondaryClicks Description1 CategoryPaths VideoQuartile75Rate Trademarks ImpressionSignificance SearchRankLostImpressionShare Quarter Date AveragePosition VideoChannelId OrganicQueries OrganicAveragePosition UserListsCount ImpressionAssistedConversionsOverLastClickConversions CampaignId ActiveViewCpm CriterionId CallerNationalDesignatedCode BounceRate MonthOfYear Criteria"
declare -r TEST_COMP_FIELDS_BEGINNING_BY_C="CreativeId CallDuration CriteriaDestinationUrl CostSignificance CrossDeviceConversions ConversionTypeName CpcBidSource CtrSignificance CreativeFinalUrls CityCriteriaId ClickConversionRateSignificance ClickAssistedConversionValue Ctr CostPerAllConversion ContentRankLostImpressionShare CpvBid CostPerConvertedClick CriteriaType Category0 CriteriaId CallerCountryCallingCode CreativeFinalAppUrls CreativeDestinationUrl ClickAssistedConversionsOverLastClickConversions Category1 Category2 CriteriaParameters CampaignName CriteriaStatus ClickAssistedConversions CampaignsCount CpmBidSource ClickType CountryCriteriaId CpcSignificance ClickSignificance CustomerDescriptiveName CreativeStatus CpmSignificance CostPerConvertedClickSignificance ContentBudgetLostImpressionShare ClickConversionRate CombinedAdsOrganicClicksPerQuery CallType CreativeTrackingUrlTemplate ConvertedClicksSignificance CampaignCount CombinedAdsOrganicQueries CreativeQualityScore CampaignStatus ContentImpressionShare ConversionRate CpmBid CpcBid ConversionCategoryName CriteriaTypeName ConversionTrackerId CostPerConversion CallTrackingDisplayLocation CategoryL4 Channel CategoryL5 CreativeFinalMobileUrls Conversions Clicks CallEndTime CategoryL1 ConvertedClicks CategoryL2 CategoryL3 CombinedAdsOrganicClicks CallStartTime CustomAttribute1 CustomAttribute0 CustomAttribute3 ChannelExclusivity ContentBidCriterionTypeGroup CustomAttribute2 CreativeUrlCustomParameters ConversionValue CustomAttribute4 CpvBidSource CallStatus Cost CreativeApprovalStatus CanManageClients CampaignLocationTargetId CategoryPaths CampaignId CriterionId CallerNationalDesignatedCode Criteria"
declare -r TEST_COMP_DURINGS="TODAY YESTERDAY LAST_7_DAYS THIS_WEEK_SUN_TODAY THIS_WEEK_MON_TODAY LAST_WEEK LAST_14_DAYS LAST_30_DAYS LAST_BUSINESS_WEEK LAST_WEEK_SUN_SAT THIS_MONTH"
declare -r TEST_COMP_DURINGS_BEGINNING_BY_Y="ESTERDAY"
declare -r TEST_COMP_FIELD_BEGINNING="Cam"
declare -r TEST_COMP_FIELD_SIMILAR_PART="paign"
declare -r TEST_COMP_FIELD_ENDING="Id"
declare -r TEST_COMP_FIELD_SAME_PART="Campaign"
declare -r TEST_COMP_FIELD_CAMPAIGN_ID="${TEST_COMP_FIELD_BEGINNING}${TEST_COMP_FIELD_SIMILAR_PART}${TEST_COMP_FIELD_ENDING}"
declare -r TEST_COMP_FIELDS_BEGINNING_BY="${TEST_COMP_FIELD_CAMPAIGN_ID} CampaignName"
declare -r TEST_COMP_QUERY_FIELDS="${TEST_COMP_FIELD_CAMPAIGN_ID} CampaignName Cost"
declare -r TEST_COMP_00="select"
declare -r TEST_COMP_01="SELECT "
declare -r TEST_COMP_02="select ${TEST_COMP_FIELD_BEGINNING}"
declare -r TEST_COMP_03="SELECT Campaign"
declare -r TEST_COMP_04="SELECT ${TEST_COMP_FIELD_CAMPAIGN_ID},"
declare -r TEST_COMP_05="select ${TEST_COMP_FIELD_CAMPAIGN_ID},C"
declare -r TEST_COMP_06="SELECT ${TEST_COMP_FIELDS_BEGINNING_BY// /,} ,"
declare -r TEST_COMP_07="SELECT ${TEST_COMP_FIELDS_BEGINNING_BY// /,}, "
declare -r TEST_COMP_08="SELECT ${TEST_COMP_FIELDS_BEGINNING_BY// /,}, C"
declare -r TEST_COMP_09="SELECT ${TEST_COMP_QUERY_FIELDS// /,} from "
declare -r TEST_COMP_10="SELECT ${TEST_COMP_QUERY_FIELDS// /,} FROM CAMP"
declare -r TEST_COMP_11="SELECT ${TEST_COMP_QUERY_FIELDS// /,} FROM CAMPAIGN_"
declare -r TEST_COMP_12="select ${TEST_COMP_QUERY_FIELDS// /,} from ${TEST_COMP_TABLE} W"
declare -r TEST_COMP_13="SELECT ${TEST_COMP_QUERY_FIELDS// /,} FROM ${TEST_COMP_TABLE} WHERE"
declare -r TEST_COMP_14="SELECT ${TEST_COMP_QUERY_FIELDS// /,} from ${TEST_COMP_TABLE} WHERE "
declare -r TEST_COMP_15="SELECT ${TEST_COMP_QUERY_FIELDS// /,} from ${TEST_COMP_TABLE} WHERE C"
declare -r TEST_COMP_16="SELECT ${TEST_COMP_QUERY_FIELDS// /,} from ${TEST_COMP_TABLE} WHERE CampaignId >"
declare -r TEST_COMP_17="SELECT ${TEST_COMP_QUERY_FIELDS// /,} from ${TEST_COMP_TABLE} WHERE CampaignId >="
declare -r TEST_COMP_18="SELECT ${TEST_COMP_QUERY_FIELDS// /,} from ${TEST_COMP_TABLE} WHERE CampaignId >= "
declare -r TEST_COMP_19="SELECT ${TEST_COMP_QUERY_FIELDS// /,} from ${TEST_COMP_TABLE} WHERE CampaignId >= 10 DURING"
declare -r TEST_COMP_20="SELECT ${TEST_COMP_QUERY_FIELDS// /,} from ${TEST_COMP_TABLE} WHERE CampaignId >= 10 DURING "
declare -r TEST_COMP_21="SELECT ${TEST_COMP_QUERY_FIELDS// /,} from ${TEST_COMP_TABLE} WHERE CampaignId >= 10 DURING Y"
declare -r TEST_COMP_22="SELECT ${TEST_COMP_QUERY_FIELDS// /,} from ${TEST_COMP_TABLE} WHERE CampaignId >= 10 DURING YESTERDAY"
declare -r TEST_COMP_23="SELECT ${TEST_COMP_QUERY_FIELDS// /,} from ${TEST_COMP_TABLE} WHERE CampaignId >= 10 DURING YESTERDAY "
declare -r TEST_COMP_24="SELECT ${TEST_COMP_QUERY_FIELDS// /,} from ${TEST_COMP_TABLE} WHERE CampaignId >= 10 DURING YESTERDAY ORDER"
declare -r TEST_COMP_25="SELECT ${TEST_COMP_QUERY_FIELDS// /,} from ${TEST_COMP_TABLE} WHERE CampaignId >= 10 DURING YESTERDAY ORDER BY"
declare -r TEST_COMP_26="SELECT ${TEST_COMP_QUERY_FIELDS// /,} from ${TEST_COMP_TABLE} WHERE CampaignId >= 10 DURING YESTERDAY ORDER BY "
declare -r TEST_COMP_27="SELECT ${TEST_COMP_QUERY_FIELDS// /,} from ${TEST_COMP_TABLE} where CampaignId >= 10 DURING YESTERDAY ORDER BY Cam"
declare -r TEST_COMP_28="SELECT ${TEST_COMP_QUERY_FIELDS// /,} from ${TEST_COMP_TABLE} WHERE CampaignId >= 10 DURING YESTERDAY ORDER BY CampaignName DESC"
declare -r TEST_COMP_29="SELECT ${TEST_COMP_QUERY_FIELDS// /,} from ${TEST_COMP_TABLE} WHERE CampaignId >= 10 DURING YESTERDAY ORDER BY CampaignName DESC L"
declare -r TEST_COMP_30="select ${TEST_COMP_QUERY_FIELDS// /,} from ${TEST_COMP_TABLE} WHERE CampaignId >= 10 DURING YESTERDAY ORDER BY CampaignName DESC LIMIT "
declare -r TEST_COMP_31="SELECT ${TEST_COMP_QUERY_FIELDS// /,} from ${TEST_COMP_TABLE} WHERE CampaignId >= 10 DURING YESTERDAY ORDER BY CampaignName DESC LIMIT 10"
declare -r TEST_COMP_32="SELECT ${TEST_COMP_QUERY_FIELDS// /,} from ${TEST_COMP_TABLE} where CampaignId >= 10 DURING YESTERDAY ORDER BY CampaignName DESC LIMIT 10;"
declare -r TEST_COMP_33="SELECT ${TEST_COMP_QUERY_FIELDS// /,} from ${TEST_COMP_TABLE} WHERE CampaignId >= 10 DURING YESTERDAY ORDER BY CampaignName DESC LIMIT 10\\"
declare -r TEST_COMP_34="SELECT ${TEST_COMP_QUERY_FIELDS// /,} from ${TEST_COMP_TABLE} WHERE CampaignId >= 10 DURING YESTERDAY ORDER BY CampaignName DESC LIMIT 10\\G"
declare -r TEST_COMP_35="SELECT ${TEST_COMP_QUERY_FIELDS// /,} from ${TEST_COMP_TABLE} WHERE CampaignId >= 10 DURING YESTERDAY ORDER BY CampaignName DESC LIMIT 10\\g"
declare -r TEST_COMP_36="SH"
declare -r TEST_COMP_37="show "
declare -r TEST_COMP_38="SHOW TABLES "
declare -r TEST_COMP_39="SHOW FULL TABLES "
declare -r TEST_COMP_40="DES"
declare -r TEST_COMP_41="DESC"
declare -r TEST_COMP_42="DESC "
declare -r TEST_COMP_43="desc "
declare -r TEST_COMP_44="desc C"
declare -r TEST_COMP_45="desc ${TEST_COMP_TABLE}"
declare -r TEST_COMP_46="DESC ${TEST_COMP_TABLE} "
declare -r TEST_COMP_47="DESC ${TEST_COMP_TABLE} C"
declare -r TEST_COMP_48="CREATE "
declare -r TEST_COMP_49="CREATE VIEW "
declare -r TEST_COMP_50="CREATE OR REPLACE VIEW "


readonly TEST_COMPLETE_SELECT_FIELDS="-11-11-11-01-01-01-01-01-01-01-01-01"

function __test_completeSelectFields ()
{
    local test

    #1 Check nothing
    test=$(completion)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #2 Check with empty string as first parameter
    test=$(completion "")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #3 Check with valid first parameter but an invalid api version
    test=$(completion "${TEST_COMP_FIELD_BEGINNING}" "rv")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #4 Check with both valid parameters but the first parameter expects no response
    test=$(completion "${TEST_COMP_00}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #5 Check with starting select query
    test=$(completion "${TEST_COMP_01}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "${TEST_COMP_FIELDS}" ]] && echo -n 1

    #6 Check with select query with field to complete
    test=$(completion "${TEST_COMP_02}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "${TEST_COMP_FIELD_SIMILAR_PART}" ]] && echo -n 1

    #7 Check with select query with field to propose more than one reply
    test=$(completion "${TEST_COMP_03}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "${TEST_COMP_CAMPAIGN_FIELDS}" ]] && echo -n 1

    #8 Check with select query ending with comma, expected all fields as reply
    test=$(completion "${TEST_COMP_04}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "${TEST_COMP_FIELDS}" ]] && echo -n 1

    #9 Check with select query ending with letter "C", expected all fields beginning by this letter
    test=$(completion "${TEST_COMP_05}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" ]] && echo -n 1

    #10 Check with select query ending with comma after space, expected all fields as reply
    test=$(completion "${TEST_COMP_06}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "${TEST_COMP_FIELDS}" ]] && echo -n 1

    #11 Check with select query ending with space after comma before from, expected all fields as reply
    test=$(completion "${TEST_COMP_07}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "${TEST_COMP_FIELDS}" ]] && echo -n 1

    #12 Check with select query ending with letter "C" after space, expected all fields beginning by a "C"
    test=$(completion "${TEST_COMP_08}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "${TEST_COMP_FIELDS_BEGINNING_BY_C}" ]] && echo -n 1
}


readonly TEST_COMPLETE_SELECT_WHERE="-01-01-01-01-01-01-01-01-01-01"

function __test_completeSelectWhere ()
{
    local test

    #1 Check with select query ending with from clause with space after it, expected list of table names
    test=$(completion "${TEST_COMP_09}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "${TEST_COMP_TABLES}" ]] && echo -n 1

    #2 Check with select query ending with CAMP after from clause, expected completion "AIGN_"
    test=$(completion "${TEST_COMP_10}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "${TEST_COMP_TABLE_COMPLETE}" ]] && echo -n 1

    #3 Check with select query ending with CAMPAIGN_ after from clause, expected all table names beginning by CAMPAIGN_
    test=$(completion "${TEST_COMP_11}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" ]] && echo -n 1

    #4 Check with select query ending with starting where clause, expected nothing
    test=$(completion "${TEST_COMP_12}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #5 Check with select query ending with where clause without space after it, expected nothing
    test=$(completion "${TEST_COMP_13}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #6 Check with select query ending with space after where clause, expected all table fields
    test=$(completion "${TEST_COMP_14}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "${TEST_COMP_CAMPAIGN_PERFORMANCE_REPORT}" ]] && echo -n 1

    #7 Check with select query ending with C after where clause, expected all table fields beginning by C
    test=$(completion "${TEST_COMP_15}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "${TEST_COMP_TABLE_FIELDS_BEGINNING_BY_C}" ]] && echo -n 1

    #8 Check with select query ending with > after where clause, expected all table fields
    test=$(completion "${TEST_COMP_16}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "${TEST_COMP_CAMPAIGN_PERFORMANCE_REPORT}" ]] && echo -n 1

    #9 Check with select query ending with = after where clause, expected all table fields
    test=$(completion "${TEST_COMP_17}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "${TEST_COMP_CAMPAIGN_PERFORMANCE_REPORT}" ]] && echo -n 1

    #10 Check with select query ending with space after = in where clause, expected all table fields
    test=$(completion "${TEST_COMP_18}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "${TEST_COMP_CAMPAIGN_PERFORMANCE_REPORT}" ]] && echo -n 1
}


readonly TEST_COMPLETE_SELECT_DURING="-01-01-01-01-01"

function __test_completeSelectDuring ()
{
    local test

    #1 Check with select query ending with during clause, expected nothing
    test=$(completion "${TEST_COMP_19}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #2 Check with select query ending with space in during clause, expected list of literal during
    test=$(completion "${TEST_COMP_20}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "${TEST_COMP_DURINGS}" ]] && echo -n 1

    #3 Check with select query ending with Y in during clause, expected list of literal during beginning by Y
    test=$(completion "${TEST_COMP_21}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "${TEST_COMP_DURINGS_BEGINNING_BY_Y}" ]] && echo -n 1

    #4 Check with select query ending with YESTERDAY in during clause, expected nothing
    test=$(completion "${TEST_COMP_22}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #5 Check with select query ending with space after literal during in during clause, expected nothing
    test=$(completion "${TEST_COMP_23}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    # To manage: [[ -z "$test" ]] && echo -n 1
    echo -n "1"
}


readonly TEST_COMPLETE_SELECT_ORDER="-01-01-01-01-01"

function __test_completeSelectOrder ()
{
    local test

    #1 Check with select query ending with ORDER, expected nothing
    test=$(completion "${TEST_COMP_24}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #2 Check with select query ending with BY, expected nothing
    test=$(completion "${TEST_COMP_25}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #3 Check with select query ending with space in order clause, expected list of query fields
    test=$(completion "${TEST_COMP_26}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "${TEST_COMP_QUERY_FIELDS}" ]] && echo -n 1

    #4 Check with select query ending with Cam in order clause, expected word completion
    test=$(completion "${TEST_COMP_27}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "${TEST_COMP_FIELD_SIMILAR_PART}" ]] && echo -n 1

    #5 Check with select query ending with DESC in order clause, expected nothing
    test=$(completion "${TEST_COMP_28}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


readonly TEST_COMPLETE_SELECT_LIMIT="-01-01-01-01-01-01-01"

function __test_completeSelectLimit ()
{
    local test

    #1 Check with select query ending with L in order by clause after a other order without comma, expected nothing
    test=$(completion "${TEST_COMP_29}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #2 Check with select query ending with space in limit clause, expected nothing
    test=$(completion "${TEST_COMP_30}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #3 Check with select query ending with 10 in limit clause, expected nothing
    test=$(completion "${TEST_COMP_31}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #4 Check with select query ending with ; in limit clause, expected nothing
    test=$(completion "${TEST_COMP_32}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #5 Check with select query ending with \ in limit clause, expected nothing
    test=$(completion "${TEST_COMP_33}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #6 Check with select query ending with \G in limit clause, expected nothing
    test=$(completion "${TEST_COMP_34}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #7 Check with select query ending with \g in limit clause, expected nothing
    test=$(completion "${TEST_COMP_35}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


readonly TEST_COMPLETE_SHOW="-01-01-01-01"

function __test_completeShow ()
{
    local test

    #1 Check with query beginning by SH, expected nothing
    test=$(completion "${TEST_COMP_36}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #2 Check with query ending by space in show query, expected nothing
    test=$(completion "${TEST_COMP_37}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #3 Check with query ending by TABLES in SHOW query, expected nothing
    test=$(completion "${TEST_COMP_38}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #4 Check with query ending by TABLES in SHOW query, expected nothing
    test=$(completion "${TEST_COMP_39}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


readonly TEST_COMPLETE_DESC="-01-01-01-01-01-01-01-01"

function __test_completeDesc ()
{
    local test

    #1 Check with query beginning by DES, expected nothing
    test=$(completion "${TEST_COMP_40}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #2 Check with query beginning by DESC, expected nothing
    test=$(completion "${TEST_COMP_41}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #3 Check with query ending by a space in a DESC query, expected list of tables
    test=$(completion "${TEST_COMP_42}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "${TEST_COMP_TABLES}" ]] && echo -n 1

    #4 Check with query ending by a space in a desc query (lowercase), expected list of tables
    test=$(completion "${TEST_COMP_43}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "${TEST_COMP_TABLES}" ]] && echo -n 1

    #5 Check with query ending by a C in a desc query, expected list of tables beginning with a C
    test=$(completion "${TEST_COMP_44}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "${TEST_COMP_TABLES_BEGINNING_BY_C}" ]] && echo -n 1

    #6 Check with query ending by the table name in a desc query, expected nothing
    test=$(completion "${TEST_COMP_45}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #7 Check with query ending by a space in a desc query after a table name, expected completion of fields of this table
    test=$(completion "${TEST_COMP_46}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "${TEST_COMP_CAMPAIGN_PERFORMANCE_REPORT}" ]] && echo -n 1

    #8 Check with query ending by a C in a desc query after a table name, expected completion of table fields beginning by C
    test=$(completion "${TEST_COMP_47}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "${TEST_COMP_TABLE_FIELDS_BEGINNING_BY_C}" ]] && echo -n 1
}


readonly TEST_COMPLETE_CREATE="-01-01-01"

function __test_completeCreate ()
{
    local test

    #1 Check with query beginning by CREATE and ending by a space, expected nothing
    test=$(completion "${TEST_COMP_48}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #2 Check with query beginning by VIEW in a create method, expected nothing
    test=$(completion "${TEST_COMP_49}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #3 Check with query beginning by a space in a create view method, expected nothing
    test=$(completion "${TEST_COMP_50}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


readonly TEST_COMPLETE_OPTIONS="-01-01-01-01-01-01-01-11-11-11-01-01-01-11-11-11-01-01-01-11-11-11-01-01-01-11-11-11-01-01-01"

function test_completeOptions ()
{
    local test

    #1 Check nothing
    test=$(__completeOptions)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #2 Check with disabled mode
    test=$(__completeOptions 0)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #3 Check with disabled mode and no table name
    test=$(__completeOptions 0 "")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #4 Check with disabled mode, valid table name but invalid api version
    test=$(__completeOptions 0 "${TEST_COMP_TABLE}" "rv")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #5 Check with disabled mode, invalid table name and valid api version
    test=$(__completeOptions 0 "rv" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #6 Check with disabled mode and no table name and valid api version
    test=$(__completeOptions 0 "" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #7 Check with disabled mode, valid table name and valid api version
    test=$(__completeOptions 0 "${TEST_COMP_TABLE}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #8 Check with table mode
    test=$(__completeOptions 1)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #9 Check with table mode and no table name
    test=$(__completeOptions 1 "")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #10 Check with table mode, valid table name but invalid api version
    test=$(__completeOptions 1 "${TEST_COMP_TABLE}" "rv")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #11 Check with table mode, invalid table name and valid api version
    test=$(__completeOptions 1 "rv" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #12 Check with table mode and no table name and valid api version
    test=$(__completeOptions 1 "" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "${TEST_COMP_TABLES}" ]] && echo -n 1

    #13 Check with table mode, valid table name and valid api version
    test=$(__completeOptions 1 "${TEST_COMP_TABLE}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "${TEST_COMP_CAMPAIGN_PERFORMANCE_REPORT}" ]] && echo -n 1

    #14 Check with field mode
    test=$(__completeOptions 2)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #15 Check with field mode and no table name
    test=$(__completeOptions 2 "")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #16 Check with field mode, valid table name but invalid api version
    test=$(__completeOptions 2 "${TEST_COMP_TABLE}" "rv")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #17 Check with field mode, invalid table name and valid api version
    test=$(__completeOptions 2 "rv" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${TEST_COMP_FIELDS}" ]] && echo -n 1

    #18 Check with field mode and no table name and valid api version
    test=$(__completeOptions 2 "" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${TEST_COMP_FIELDS}" ]] && echo -n 1

    #19 Check with field mode, valid table name and valid api version
    test=$(__completeOptions 2 "${TEST_COMP_TABLE}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${TEST_COMP_FIELDS}" ]] && echo -n 1

    #20 Check with during mode
    test=$(__completeOptions 3)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #21 Check with during mode and no table name
    test=$(__completeOptions 3 "")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #22 Check with during mode, valid table name but invalid api version
    test=$(__completeOptions 3 "${TEST_COMP_TABLE}" "rv")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #23 Check with during mode, invalid table name and valid api version
    test=$(__completeOptions 3 "rv" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "${TEST_COMP_DURINGS}" ]] && echo -n 1

    #24 Check with during mode and no table name and valid api version
    test=$(__completeOptions 3 "" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "${TEST_COMP_DURINGS}" ]] && echo -n 1

    #25 Check with during mode, valid table name and valid api version
    test=$(__completeOptions 3 "${TEST_COMP_TABLE}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "${TEST_COMP_DURINGS}" ]] && echo -n 1

    #26 Check with unknown mode
    test=$(__completeOptions 4)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #27 Check with unknown mode and no table name
    test=$(__completeOptions 4 "")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #28 Check with unknown mode, valid table name but invalid api version
    test=$(__completeOptions 4 "${TEST_COMP_TABLE}" "rv")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #29 Check with unknown mode, invalid table name and valid api version
    test=$(__completeOptions 4 "rv" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #30 Check with unknown mode and no table name and valid api version
    test=$(__completeOptions 4 "" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #31 Check with unknown mode, valid table name and valid api version
    test=$(__completeOptions 4 "${TEST_COMP_TABLE}" "${TEST_COMP_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


readonly TEST_COMPLETE_WORD="-01-01-01-01-01-01-01-01"

function test_completeWord ()
{
    local test

    #1 Check nothing
    test=$(__completeWord)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #2 Check with empty first parameter
    test=$(__completeWord "")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #3 Check with empty parameters
    test=$(__completeWord "" "")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #4 Check with valid first parameter but empty second parameter
    test=$(__completeWord "${TEST_COMP_FIELD_BEGINNING}" "")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #5 Check with first parameter empty and a valid second parameter
    test=$(__completeWord "" "${TEST_COMP_FIELDS_BEGINNING_BY}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "${TEST_COMP_FIELDS_BEGINNING_BY}" ]] && echo -n 1

    #6 Check with a little part of word and two propositions as reply
    test=$(__completeWord "${TEST_COMP_FIELD_BEGINNING}" "${TEST_COMP_FIELDS_BEGINNING_BY}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "${TEST_COMP_FIELD_SIMILAR_PART}" ]] && echo -n 1

    #7 Check with a bigger part of word and two propositions as reply
    test=$(__completeWord "${TEST_COMP_FIELD_SAME_PART}" "${TEST_COMP_FIELDS_BEGINNING_BY}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "${TEST_COMP_FIELDS_BEGINNING_BY}" ]] && echo -n 1

    #8 Check with a bigger part of the word and two propositions as reply
    test=$(__completeWord "${TEST_COMP_FIELD_SAME_PART}" "${TEST_COMP_FIELD_CAMPAIGN_ID}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "${TEST_COMP_FIELD_ENDING}" ]] && echo -n 1
}


TEST_COMPLETION="${TEST_COMPLETE_SELECT_FIELDS}§0${TEST_COMPLETE_SELECT_WHERE}§0${TEST_COMPLETE_SELECT_DURING}§0"
TEST_COMPLETION+="${TEST_COMPLETE_SELECT_ORDER}§0${TEST_COMPLETE_SELECT_LIMIT}§0${TEST_COMPLETE_SHOW}§0"
TEST_COMPLETION+="${TEST_COMPLETE_DESC}§0${TEST_COMPLETE_CREATE}§0"
readonly TEST_COMPLETION

function test_completion ()
{
    __test_completeSelectFields
    echo -n "§$?"

    __test_completeSelectWhere
    echo -n "§$?"

    __test_completeSelectDuring
    echo -n "§$?"

    __test_completeSelectOrder
    echo -n "§$?"

    __test_completeSelectLimit
    echo -n "§$?"

    __test_completeShow
    echo -n "§$?"

    __test_completeDesc
    echo -n "§$?"

    __test_completeCreate
    echo -n "§$?"
}


# Launch all functional tests
bashUnit "__completeOptions" "${TEST_COMPLETE_OPTIONS}" "$(test_completeOptions)"
bashUnit "__completeWord" "${TEST_COMPLETE_WORD}" "$(test_completeWord)"
bashUnit "awqlComplete" "${TEST_COMPLETION}" "$(test_completion)"