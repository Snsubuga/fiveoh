@isTest
private class BatchUserValidationsCountTest {
   
    @testSetup static void userSetup() {
        // Create users and species
        List<Profile> userProfiles = [SELECT Id FROM Profile WHERE Name = 'Data Validator'];
        List<UserRole> roles = [SELECT Id FROM UserRole WHERE Name = 'BioSightings Member'];
        
        
        List<String> speciesGroups = new List<String> {'Mammals', 'Fish', 'Plants'};
        
        // Create some users
        List<User> users = new List<User>();
        for (Integer index = 0; index < 2; index++) {
            User user = new User(Alias = 'userd'+index, Email='user2d@testuser.org', 
                EmailEncodingKey='UTF-8', LastName='Tester', LanguageLocaleKey='en_US', 
                LocaleSidKey='en_US', ProfileId = userProfiles[0].Id, UserRoleId = roles[0].Id,
                TimeZoneSidKey='America/Los_Angeles', UserName='batchtest'+index+'userguy@testorg.com', 
                Default_Sighting_Location__Latitude__s = 30, Default_Sighting_Location__Longitude__s = -140);
            users.add(user);
        }
        insert users;
    }
    @isTest static void testBatchProcess() {
        
        List<User> users = [Select Id, Sightings_Validated__c from User where Email = 'user2d@testuser.org'];
        
        // Create some species
        List<Species__c> species = new List<Species__c>();
        List<String> speciesGroups = new List<String> {'Mammals', 'Fish', 'Plants'};
        for (Integer index = 0; index < 3; index++) {          
            Species__c specie = new Species__c(Name = 'Species'+index, External_Id__c = index+'species', Species_Group__c = speciesGroups[math.mod(index, 3)]);
            species.add(specie);
        }
        insert species;
        
        // Create some sightings
        List<Sighting__c> sightings = new List<Sighting__c>();
        for (Integer index = 1; index < 101; index++) {
            Sighting__c sighting = new Sighting__c();
            sighting.Date__c = date.today().addDays(-Integer.valueOf(10 * Math.random()));
            sighting.Location_Precision__c = '10 meters';
            sighting.Location__Latitude__s = index/50;
            sighting.Location__Longitude__s = -180;
            sighting.Number_of_Animals__c = index;
            sighting.OwnerId = users[0].Id;
            sighting.Species__c = species[math.mod(index, 2)].id;
            sighting.Validation_Status__c = 'Not Validated';
            sightings.add(sighting);
        }
        insert sightings;
        
        System.runAs(users[0]) {
            for (Integer x = 0; x < 25; x++) {
                sightings[x].Validation_Status__c = 'Approved';
            }
            update sightings;
        }       
        
        Test.startTest();
        
        BatchUserValidationsCount validationCount = new BatchUserValidationsCount();
        ID batchprocessid = Database.executeBatch(validationCount);
        Test.stopTest();
        System.assertEquals(25, [Select Sightings_Validated__c from User where Id =:users[0].Id].Sightings_Validated__c);
        System.assertEquals(null, [Select Sightings_Validated__c from User where Id =:users[1].Id].Sightings_Validated__c);
    }
}