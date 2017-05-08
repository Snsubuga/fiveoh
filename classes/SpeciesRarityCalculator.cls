public class SpeciesRarityCalculator {
   
    //public static Set<Id> processedIds = new Set<Id>();
    public static Boolean firstRun = true;
        
    // set a species rarity field given the count of the species' approved sighting
    private static Species__c setRarityField(Species__c species, Integer count, Species_Rarity_Setting__mdt raritySetting) {
        
        if (count == raritySetting.Extinction__c) {
            species.Rarity__c = 'Extinct';
        }
        else if (count <= raritySetting.Endangered__c) {
            species.Rarity__c = 'Endangered';
        }
        else if (count <= raritySetting.Rare__c) {
            species.Rarity__c = 'Rare';
        }
        else {
            species.Rarity__c = 'Common';
        } 
        return species;      
    }
    
    public static void updateSpeciesRarity(List<Sighting__c> sightings) {
        
        // Set to be used to store the species Ids of the passed in sightings
        Set<String> speciesIds = new Set<String>();
        for (Sighting__c sighting : sightings) {
            speciesIds.add(sighting.Species__c);
        }
        
        // List of species whose rarity is to be updated, based on the passed in sightings
        List<Species__c> speciesList = new List<Species__c>();
                
        // Date ranges, between today and last 12 months
        Date thisDate = date.today();
        Date firstDate = date.today().addMonths(-12);
               
        // Trigger handles 200 sighting records at a time, so this list is more than adequate to hold the results per species.
        List<AggregateResult> results = [Select Species__c, SUM(Number_of_Animals__c) FROM Sighting__c Where 
                Species__c IN:speciesIds AND
                Validation_Status__c = 'Approved' AND
                Date__c  <=:thisDate AND
                Date__c >=:firstDate GROUP BY Species__c];
        
        // Map to contain a count of the number of animals in approved sightings per species
        Map<String, Integer> speciesCount = new Map<String, Integer>();
        
        // 
        for (AggregateResult result : results) {
            speciesCount.put(String.valueOf(result.get('Species__c')), Integer.valueOf(result.get('expr0')));
        }
        
        // This handles cases where the aggregate results won't return any approved sightings for some species
        // in the generated species list. In such cases, I set the count of approved sightings for such species
        // to ZERO. This is why in case of a sighting insert for a species with no approved sightings, 
        // the species' rarity will be set to Extinct (coz of the zero approved sightings). 
        // Without these lines of code, such species will have a NULL value of rarity, which to me is not cool.
        for (String speciesId : speciesIds) {
            if (!speciesCount.containskey(speciesId)) {
                speciesCount.put(speciesId, 0);
            }
        }
        
        // Custom metadata type that has the defined thresholds for extinct, endangered, rare and common
        List<Species_Rarity_Setting__mdt> raritySettings = [Select Extinction__c, Endangered__c, Rare__c, Common__c 
                                                                from 
                                                            Species_Rarity_Setting__mdt limit 1];

        // Get all the referred to species from Salesforce, set their rarity field and then update the records
        for (Species__c species : [SELECT Id, Rarity__c FROM Species__c where Id IN:speciesCount.keyset()]) {                
            speciesList.add(setRarityField(species, speciesCount.get(species.Id), raritySettings[0]));
        }
        update speciesList;
    }
}