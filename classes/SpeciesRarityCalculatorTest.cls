@isTest
private class SpeciesRarityCalculatorTest {
   
    @isTest static void testInsert() {
        // List to hold some species group names
        List<String> speciesGroups = new List<String> {'Mammals', 'Fish', 'Plants', 'Fungi', 'Arachnids','Birds'};
        
        // Create 200 species, across the 6 species groups
        List<Species__c> species = new List<Species__c>();              
        for (Integer index = 1; index < 201; index++) {           
            Species__c specie = new Species__c(Name = 'Species'+index, External_Id__c = index+'species', Species_Group__c = speciesGroups[math.mod(index, 6)]);
            species.add(specie);
        }
        database.insert(species);
        
        // Check that the species' rarity is set to null initially
        List<Species__c> speciez = [Select Rarity__c from Species__c];
        for (Species__c specie : speciez) {
            System.assertEquals(Null, specie.Rarity__c);
        }
               
        // Create 1000 sightings, equally shared across the 200 species
        List<Sighting__c> sightings = new List<Sighting__c>();
        for (Integer index = 1; index < 1001; index++) {
            Sighting__c sighting = new Sighting__c();
            sighting.Date__c = date.today().addDays(-Integer.valueOf(10 * Math.random()));
            sighting.Location_Precision__c = '10 meters';
            sighting.Location__Latitude__s = index/50;
            sighting.Location__Longitude__s = -180;
            sighting.Number_of_Animals__c = index;
            sighting.Species__c = species[math.mod(index, 200)].id;
            sighting.Validation_Status__c = 'Not Validated';
            sightings.add(sighting);
        }
        insert sightings;

        test.startTest();
        speciez = [Select Rarity__c from Species__c];
        test.stopTest();

        // Check that the trigger sets the rarity of each species to extinct if there are no approved sightings
        for (Species__c specie : speciez) {
            System.assertEquals('Extinct', specie.rarity__c);
        }
    }
    
    @isTest static void testValidationStatusUpdateToEndangered() {
                
        // Create 100 species, across the 6 species groups
        List<Species__c> species = new List<Species__c>();              
        for (Integer index = 1; index < 101; index++) {           
            Species__c specie = new Species__c(Name = 'Species'+index, External_Id__c = index+'species', Species_Group__c = 'Birds');
            species.add(specie);
        }
        database.insert(species);
                
        // Create 100 sightings, equally shared across the 100 species
        // This ensures that we have sightings across the entire
        // endangered threshold ie 1-100
        List<Sighting__c> sightings = new List<Sighting__c>();
        for (Integer index = 0; index < 100; index++) {
            Sighting__c sighting = new Sighting__c();
            sighting.Date__c = date.today().addDays(-Integer.valueOf(10 * Math.random()));
            sighting.Location_Precision__c = '10 meters';
            sighting.Location__Latitude__s = index/50;
            sighting.Location__Longitude__s = -180;
            sighting.Number_of_Animals__c = index + 1;
            sighting.Species__c = species[index].id;
            sighting.Validation_Status__c = 'Not Validated';
            sightings.add(sighting);
        }
        database.insert(sightings);
        
        // Approve all the sightings
        for (Sighting__c sighting : sightings) {
            sighting.Validation_Status__c = 'Approved';
        }
        database.update(sightings);
        test.startTest();
        List<Species__c> speciez = [Select Rarity__c from Species__c];
        test.stopTest();

        // Check that the trigger sets the rarity of each species to endangered
        for (Species__c specie : speciez) {
            System.assertEquals('Endangered', specie.rarity__c);
        }
    }
    
    @isTest static void testEndangeredWithMultipleSightingsPerSpecies() {
        List<Species__c> species = new List<Species__c>();
        for (Integer index = 1; index < 6; index++) {
            Species__c specie = new Species__c(Name = 'Species'+index, External_Id__c = index+'species', Species_Group__c = 'Mammals');
            species.add(specie);
        }
        insert species;
        
        List<Sighting__c> sightings = new List<Sighting__c>();
        for (Integer index = 0; index < 500; index++) {
            Sighting__c sighting = new Sighting__c();
            sighting.Date__c = date.today().addDays(-Integer.valueOf(10 * Math.random()));
            sighting.Location_Precision__c = '10 meters';
            sighting.Location__Latitude__s = index/50;
            sighting.Location__Longitude__s = -180;
            sighting.Number_of_Animals__c = 1;
            sighting.Species__c = species[math.mod(index, 5)].id;
            sighting.Validation_Status__c = 'Not Validated';
            sightings.add(sighting);
        }
        insert sightings;
        //check that each species is currently extinct
        species = [Select Rarity__c from Species__c];
        for (Species__c specie : species) {
            System.assertEquals('Extinct', specie.Rarity__c);
        }
        for (Sighting__c sighting : sightings) {
            sighting.Validation_Status__c = 'Approved';
        }
        update sightings;
        
        // check that each species is now endangered
        species = [Select Rarity__c from Species__c];
        for (Species__c specie : species) {
            System.assertEquals('Endangered', specie.Rarity__c);
        }
    }
    /** Reject a species' previously approved sightings
    ** should reset the species' rarity
    **/
    @isTest static void testValidationStatusUpdateToRejected() {
        // List to hold some species group names
        List<String> speciesGroups = new List<String> {'Mammals', 'Fish', 'Plants', 'Fungi', 'Arachnids','Birds'};
        
        // Create 10 species, across the 6 species groups
        List<Species__c> species = new List<Species__c>();              
        for (Integer index = 1; index < 11; index++) {           
            Species__c specie = new Species__c(Name = 'Species'+index, External_Id__c = index+'species', Species_Group__c = speciesGroups[math.mod(index, 6)]);
            species.add(specie);
        }
        database.insert(species);
                
        // Create 100 sightings, equally shared across the 10 species
        List<Sighting__c> sightings = new List<Sighting__c>();
        for (Integer index = 0; index < 100; index++) {
            Sighting__c sighting = new Sighting__c();
            sighting.Date__c = date.today().addDays(-Integer.valueOf(10 * Math.random()));
            sighting.Location_Precision__c = '10 meters';
            sighting.Location__Latitude__s = index/50;
            sighting.Location__Longitude__s = -180;
            sighting.Number_of_Animals__c = 100;
            sighting.Species__c = species[math.mod(index, 10)].id;
            sighting.Validation_Status__c = 'Not Validated';
            sightings.add(sighting);
        }
        database.insert(sightings);
        // default rarity of a species with unapproved sightings is Extinct.
        species = [Select Rarity__c from Species__c];
        for (Species__c specie : species) {
            System.assertEquals('Extinct', specie.Rarity__c);
        }
        // Approve all the sightings
        for (Sighting__c sighting : sightings) {
            sighting.Validation_Status__c = 'Approved';
        }
        database.update(sightings);
        // rarity should now be common
        species = [Select Rarity__c from Species__c];
        for (Species__c specie : species) {
            System.assertEquals('Common', specie.Rarity__c);
        }
        test.startTest();
        // reject all sightings of species[0]
        for (Sighting__c sighting : sightings) {
            if (sighting.Species__c == species[0].Id) {
                sighting.Validation_Status__c = 'Rejected';
            }
        }
        update sightings;
        List<Species__c> speciez = [Select Rarity__c from Species__c];
        // The rarity of species[0] should now be extinct
        for (Species__c specie : speciez) {
            if (specie.Id == species[0].Id) {
                System.assertEquals('Extinct', specie.rarity__c);
            }
            else {
                System.assertNotEquals('Extinct', specie.rarity__c);
            }
        }
        test.stopTest();
    }
    
    /** Create a species whose sightings are older
    ** than 12 months **/
    @isTest static void testExtinctionWithDateOutOfRange() {
    
        // Create a species
        Species__c specie = new Species__c(Name = 'SpeciesX', External_Id__c = 'speciesX', Species_Group__c = 'Mammals');
        insert specie;
        
        // Create 100 sightings
        List<Sighting__c> sightings = new List<Sighting__c>();
        for (Integer index = 1; index < 501; index++) {
            Sighting__c sighting = new Sighting__c();
            sighting.Date__c = date.today().addMonths(-13);
            sighting.Location_Precision__c = '10 meters';
            sighting.Location__Latitude__s = index/50;
            sighting.Location__Longitude__s = -180;
            sighting.Number_of_Animals__c = index;
            sighting.Species__c = specie.id;
            sighting.Validation_Status__c = 'Not Validated';
            sightings.add(sighting);
        }
        insert sightings;
        
        for (Sighting__c sighting : sightings) {
            sighting.Validation_Status__c = 'Approved';
        }
        update sightings;
        // These sightings dont count so the species is extinct
        System.assertEquals('Extinct', [Select Rarity__c from Species__c where Id =:specie.Id].Rarity__c);
    }
    
    /** Create a couple of records to cover the rare range (101 - 400)
    **/
    @isTest static void testForRarity() {
    
        // Create 300 species
        List<Species__c> species = new List<Species__c>();
        for (Integer index = 0; index < 300; index++) {
            Species__c specie = new Species__c(Name = 'Species X'+index, Species_Group__c = 'Fish', External_Id__c = 'specie'+index);
            species.add(specie);
        }
        insert species;
        
        // Create 300 sightings, 1 for each species
        List<Sighting__c> sightings = new List<Sighting__c>();
        for (Integer index = 0; index < 300; index++) {
            Sighting__c sighting = new Sighting__c();
            sighting.Date__c = date.today().addDays(-Integer.valueOf(10 * Math.random()));
            sighting.Location_Precision__c = '10 meters';
            sighting.Location__Latitude__s = index/50;
            sighting.Location__Longitude__s = -180;
            sighting.Number_of_Animals__c = 101 + index;
            sighting.Species__c = species[index].Id;
            sighting.Validation_Status__c = 'Not Validated';
            sightings.add(sighting);
        }
        insert sightings;
        List<Species__c> speciesList = [Select Rarity__c from Species__c where Id IN:species];
        for (Species__c spec : speciesList) {
            System.assertNotEquals('Rare', spec.Rarity__c);
        }
        
        for (Sighting__c sighting : sightings) {
            sighting.Validation_Status__c = 'Approved';
        }
        update sightings;
        List<Species__c> speciesList2 = [Select Rarity__c from Species__c where Id IN:species];
        for (Species__c spec : speciesList2) {
            System.assertEquals('Rare', spec.Rarity__c);
        }
    
    }
    
    /** Create a couple of records to cover the common range
    ** that is, more than 400 **/  
    @isTest static void testCommonality() {
    
        // Create 400 species, across the 6 species groups
        List<Species__c> species = new List<Species__c>();              
        for (Integer index = 1; index < 401; index++) {           
            Species__c specie = new Species__c(Name = 'Species'+index, External_Id__c = index+'species', Species_Group__c = 'Other');
            species.add(specie);
        }
        database.insert(species);
                
        // Create 400 sightings, equally shared across the 400 species
        List<Sighting__c> sightings = new List<Sighting__c>();
        for (Integer index = 0; index < 400; index++) {
            Sighting__c sighting = new Sighting__c();
            sighting.Date__c = date.today().addDays(-Integer.valueOf(10 * Math.random()));
            sighting.Location_Precision__c = '10 meters';
            sighting.Location__Latitude__s = index/50;
            sighting.Location__Longitude__s = -180;
            sighting.Number_of_Animals__c = 401 + index;
            sighting.Species__c = species[index].id;
            sighting.Validation_Status__c = 'Not Validated';
            sightings.add(sighting);
        }
        database.insert(sightings);
        
        // Approve all the sightings
        for (Sighting__c sighting : sightings) {
            sighting.Validation_Status__c = 'Approved';
        }
        database.update(sightings);
        test.startTest();
        List<Species__c> speciez = [Select Rarity__c from Species__c];
        test.stopTest();

        // Check that the trigger sets the rarity of each species to endangered
        for (Species__c specie : speciez) {
            System.assertEquals('Common', specie.rarity__c);
        }
    }
    
    /** test to ensure that when approved sightings are deleted
    ** the species' rarity is updated**/
    @isTest static void testDelete() {
        // List to hold some species group names
        List<String> speciesGroups = new List<String> {'Mammals', 'Fish', 'Plants', 'Fungi', 'Arachnids','Birds'};
        
        // Create 100 species, across the 6 species groups
        List<Species__c> species = new List<Species__c>();              
        for (Integer index = 1; index < 101; index++) {           
            Species__c specie = new Species__c(Name = 'Species'+index, External_Id__c = index+'species', Species_Group__c = speciesGroups[math.mod(index, 6)]);
            species.add(specie);
        }
        database.insert(species);
        
        // Check that the species' rarity is set to null initially
        List<Species__c> speciez = [Select Rarity__c from Species__c];
        for (Species__c specie : speciez) {
            System.assertEquals(Null, specie.Rarity__c);
        }
               
        // Create 800 sightings, equally shared across the 100 species
        List<Sighting__c> sightings = new List<Sighting__c>();
        for (Integer index = 1; index < 801; index++) {
            Sighting__c sighting = new Sighting__c();
            sighting.Date__c = date.today().addDays(-Integer.valueOf(10 * Math.random()));
            sighting.Location_Precision__c = '10 meters';
            sighting.Location__Latitude__s = index/50;
            sighting.Location__Longitude__s = -180;
            sighting.Number_of_Animals__c = 500;
            sighting.Species__c = species[math.mod(index, 100)].id;
            sighting.Validation_Status__c = 'Not Validated';
            sightings.add(sighting);
        }
        insert sightings;

        for (Sighting__c sightingToApprove : sightings) {
            sightingToApprove.Validation_Status__c = 'Approved';
        }
        database.update(sightings);
        Set<String> speciesNames = new Set<String> {'Species1', 'Species2', 'Species3', 'Species45', 'Species197'};
        
        species = [Select Name, Rarity__c from Species__c where Name IN:speciesNames];
        for (Species__c specie : species) {
            System.assertNotEquals('Extinct', specie.Rarity__c);
        }
        // delete a subset of the sightings       
        List<Sighting__c> selectedSightings = [Select Id from Sighting__c where Validation_Status__c = 'Approved' and Species__r.name IN:speciesNames];
        database.delete(selectedSightings);
        
        // Check that the 
        species = [Select Name, Rarity__c from Species__c];
        for (Species__c specie : species) {
            if (speciesNames.contains(specie.Name)) {
                System.assertEquals('Extinct', specie.Rarity__c);
            }
            else {
                System.assertNotEquals('Extinct', specie.Rarity__c);
            }
        }
    }
    
    /** typical UI scenario, 
    ** editing 1 record at a time **/
    @isTest static void testSingleRecordUpdate() {
        Species__c specie = new Species__c(Name = 'Species Z', Species_Group__c = 'Fish', External_Id__c = 'Z1234');
        insert specie;
        Sighting__c sighting = new Sighting__c();
        sighting.Date__c = date.today().addDays(-100);
        sighting.Location_Precision__c = '10 meters';
        sighting.Location__Latitude__s = 70;
        sighting.Location__Longitude__s = -130;
        sighting.Number_of_Animals__c = 33;
        sighting.Validation_Status__c = 'Not Validated';
        sighting.Species__c = specie.Id;
        insert sighting;
        
        specie = [Select Rarity__c from Species__c where Id =:specie.Id];
        System.assertEquals('Extinct', specie.Rarity__c);
        
        sighting.Validation_Status__c = 'Approved';
        update specie;
        System.assertEquals('Extinct', [Select Rarity__c from Species__c where Id =:specie.Id].Rarity__c);
    }
    
}