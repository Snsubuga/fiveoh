@isTest
private class SightingsValidatorControllerTest {

    /** setting up users here so that they can be accessed across all tests
    ** this method also helps to sort out a possible mixed dml issue
    ** since Mixed DML operations within a single transaction aren’t allowed. **/
    @testSetup static void testDataSetup() {
    
        // a subset of the species groups/validation specialty
        List<String> speciesGroups = new List<String> {'Mammals', 'Fish', 'Plants', 'Fungi', 'Arachnids','Birds'};
        
        List<Profile> userProfiles = [SELECT Id FROM Profile WHERE Name in ('Citizen Scientist Volunteer', 'Data Validator', 'System Administrator') 
            order by Name asc];
            
        List<UserRole> roles = [Select Id from UserRole where DeveloperName = 'BioSightings_Member'];
        List<String> publicGroups = new List<String> {'Arachnids_Validators',
                                                        'Bird_Validators',
                                                        'Butterflies_Validators',
                                                        'Diptera_Validators',
                                                        'Dragonflies_Validators',
                                                        'Fish_Validators',
                                                        'Fungi_Validators',
                                                        'Hymenoptera_Validators',
                                                        'Mammal_Validators',
                                                        'Other_Invertebrates_Validators',
                                                        'Other_Validators',
                                                        'Plants_Validators'
                                                        };
        List<Group> pGroups = [select Id, DeveloperName from Group Where DeveloperName IN:publicGroups];
        Map<String, Group> groupsBySpecies = new Map<String, Group>();
        for (Group grp : pGroups) {
            if (grp.DeveloperName == 'Arachnids_Validators') {
                groupsBySpecies.put('Arachnids', grp);
            }
            else if (grp.DeveloperName == 'Bird_Validators') {
                groupsBySpecies.put('Birds', grp);
            }
            else if (grp.DeveloperName == 'Fish_Validators') {
                groupsBySpecies.put('Fish', grp);
            }
            else if (grp.DeveloperName == 'Fungi_Validators') {
                groupsBySpecies.put('Fungi', grp);
            }
            else if (grp.DeveloperName == 'Plants_Validators') {
                groupsBySpecies.put('Plants', grp);
            }
            else if (grp.DeveloperName == 'Mammal_Validators') {
                groupsBySpecies.put('Mammals', grp);
            }
        }
        
        
        List<User> users = new List<User>();
        for (Integer index = 0; index < 12; index++) {
            User u = new User(Alias = 'user'+index, Email='user'+index+'@testuser.org', 
                EmailEncodingKey='UTF-8', LastName='Testing'+index, LanguageLocaleKey='en_US', 
                LocaleSidKey='en_US', ProfileId = userProfiles[Math.mod(index,2)].Id, 
                Validation_Specialization__c = speciesGroups[math.mod(index, 6)],
                UserRoleId = roles[0].Id,
                TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com'+index, 
                Default_Sighting_Location__Latitude__s = 62, Default_Sighting_Location__Longitude__s = -160);
            users.add(u);
        } 
        insert users;
        
        // Assign users to public groups. 
        List<GroupMember>listGroupMember = new List<GroupMember>();
        for (User user : users) {
                GroupMember gm = new GroupMember(); 
                gm.GroupId = groupsBySpecies.get(user.Validation_Specialization__c).id;
                gm.UserOrGroupId = user.id;
                listGroupMember.add(gm);      
        }
        insert listGroupMember;
        
        // Create a System Administrator User
        User user = new User(Alias = 'admin', Email='admin@testuser.org', 
                EmailEncodingKey='UTF-8', LastName='Admin', LanguageLocaleKey='en_US', 
                LocaleSidKey='en_US', ProfileId = userProfiles[2].Id, 
                UserRoleId = roles[0].Id, UserName='adminX@testorg.com',
                TimeZoneSidKey='America/Los_Angeles', Default_Sighting_Location__Latitude__s = 62,
                Default_Sighting_Location__Longitude__s = -159);
        insert user;
    }
    
    @isTest static void testAsSystemAdministrator() {
        
        
        List<String> speciesGroups = new List<String> {'Mammals', 'Fish', 'Plants', 'Fungi', 'Arachnids','Birds'};
        
        // Create 20 species
        List<Species__c> species = new List<Species__c>();
        for (Integer index = 0; index < 20; index++) {                      
            Species__c specie = new Species__c(Name = 'Species'+index, External_Id__c = index+'species', Species_Group__c = speciesGroups[math.mod(index, 6)]);
            species.add(specie);
        }     
        database.insert(species);
                
        // Create 101 sightings
        List<Sighting__c> sightings = new List<Sighting__c>();
        for (Integer index = 0; index < 101; index++) {
            Sighting__c sighting = new Sighting__c();
            sighting.Date__c = date.today().addDays(-Integer.valueOf(10 * Math.random()));
            sighting.Location_Precision__c = '10 meters';
            sighting.Location__Latitude__s = 62;
            sighting.Location__Longitude__s = -161;
            sighting.Number_of_Animals__c = index;
            sighting.Species__c = species[math.mod(index, 20)].id;
            sighting.Validation_Status__c = 'Not Validated';
            sightings.add(sighting);
        }
        database.insert(sightings);
        
        sightings = [Select Species_Group__c, Location__c, Location__Latitude__s, Location__Longitude__s, Validation_Status__c  from Sighting__c];
        
        for (Sighting__c ss : sightings) {
            if (ss.Species_Group__c == 'Fish') {
                ss.Validation_Status__c = 'Approved';
            }
        }
        update sightings;
    
        List<User> validatorUsers = [Select Id, 
                                        Default_Sighting_Location__Latitude__s, 
                                        Default_Sighting_Location__Longitude__s,
                                        Default_Sighting_Location__c,
                                        Username,
                                        Validation_Specialization__c 
                                    from 
                                        User 
                                    where 
                                        id in 
                                    (select userorgroupid from groupmember where group.name = 'Fish Validators')                                   
                                    and
                                        Username LIKE 'standarduser%'
                                    and
                                        Profile.Name = 'Data Validator'
                                    and
                                        Default_Sighting_Location__Latitude__s != null
                                        
                                    order by
                                        CreatedDate desc
                                    ];
                                    
                    
        Integer mammalSpeciesCount = 0;
        Integer fishSpeciesCount = 0;
        for (Sighting__c s : sightings) {
            if (s.Species_Group__c == 'Mammals') {
                mammalSpeciesCount++;
            }
            else if (s.Species_Group__c == 'Fish') {
                fishSpeciesCount++;
            }
        }
        
        User adminUser = [Select Id from User where Username = 'adminX@testorg.com'];
        System.runAs(adminUser) {
            PageReference pageRef = Page.SightingsValidator;
            Test.setCurrentPage(pageRef);
            SightingsValidatorController controller = new SightingsValidatorController();     
            System.assertEquals(controller.distance, 150);
            
            List<SightingsValidatorController.SightingWrapper> wrappers = controller.getSightingWrappers();
            System.assertEquals(5, wrappers.size());            
            System.assertEquals(sightings.size(), controller.recordCount);
            System.assertEquals(21, controller.getTotalPages());
            
            // Check that the records are sorted from oldest to newest
            for (Integer index = 0; index < wrappers.size(); index++) {
                Date oldestDate = wrappers[0].sighting.Date__c;
                System.assert(oldestDate <= wrappers[index].sighting.Date__c);
                if (index != (wrappers.size() - 1)) {
                    System.assert(wrappers[index].sighting.Date__c <= wrappers[index+1].sighting.Date__c);
                }
                else {
                    System.assert(wrappers[index-1].sighting.Date__c <= wrappers[index].sighting.Date__c);
                }
            }
            
            // Create some extra sightings that are out of range
            List<Sighting__c> newSightings = new List<Sighting__c>();
            for (Integer x = 0; x < 9; x++) {
                Sighting__c sighting = new Sighting__c();
                sighting.Date__c = date.today().addDays(-Integer.valueOf(10 * Math.random()));
                sighting.Location_Precision__c = '10 meters';
                sighting.Location__Latitude__s = 82;
                sighting.Location__Longitude__s = -111;
                sighting.Number_of_Animals__c = x+1;
                sighting.Species__c = species[0].id;
                sighting.Validation_Status__c = 'Not Validated';
                newSightings.add(sighting);
            }
            insert newSightings;
            controller = new SightingsValidatorController();
            
            // Assert that the record count has not changed
            System.assertEquals(101, controller.recordCount);
            
            controller.last();
            System.assertEquals(21, controller.getPageNumber());
            
            controller.distance = 5000;
            controller.search();
            
            // Assert that the record count has changed
            System.assertEquals(110, controller.recordCount);
            
            System.assertEquals(22, controller.getTotalPages());
            // Check that we are on the first page, and that the first button is currently disabled
            System.assertEquals(1, controller.getPageNumber());
            System.assert(true, controller.getDisablePrevious());
            System.assertEquals(false, controller.getDisableNext());
            // Move to the next page and assert that the first and previous buttons are now enabled
            controller.next();
            System.assertEquals(2, controller.getPageNumber());
            System.assertEquals(false, controller.getDisablePrevious());
            
            // Move to the last page
            controller.last();
            System.assert(true, controller.getDisableNext());
            
            // Move a page back
            controller.previous();
            System.assertEquals(false, controller.getDisableNext());
            
            // Move to the first page
            controller.first();
            System.assertEquals(1, controller.getPageNumber());
            System.assert(true, controller.getDisablePrevious());
            
            // Test record selection
            wrappers = controller.getSightingWrappers();
            for (SightingsValidatorController.SightingWrapper wrapper : wrappers) {
                wrapper.selected = true;
            }
            // Move to page 2
            controller.next();
            wrappers = controller.getSightingWrappers();
            for (integer x = 0; x < wrappers.size(); x++) {
                // select only 2 of the records on page 2
                if (math.mod(x, 2) == 0) {
                    wrappers[x].selected = true;
                }
            }
            
            // return to first page
            controller.first();
            wrappers = controller.getSightingWrappers();
            
            // Check that we have all 5 records currently selected
            for (SightingsValidatorController.SightingWrapper wrapper : wrappers) {
                System.assert(true, wrapper.selected);
            }
            
            // Move to page 2
            controller.next();
            wrappers = controller.getSightingWrappers();
            // Check that we only selected 2 records on this page earlier
            for (Integer index = 0; index < wrappers.size(); index++) {
                if (math.mod(index, 2) == 0) {
                    System.assert(true, wrappers[index].selected);
                }
                else {
                    System.assertEquals(false, wrappers[index].selected);
                }
            }
            
            // clear the selection
            controller.reset();
            
            // check the 2 pages earlier to ensure that no record is currently selected.
            controller.first();
            wrappers = controller.getSightingWrappers();
            for (SightingsValidatorController.SightingWrapper wrapper : wrappers) {
                System.assertEquals(false, wrapper.selected);
            }
            // now to page 2
            controller.next();
            wrappers = controller.getSightingWrappers();
            for (SightingsValidatorController.SightingWrapper wrapper : wrappers) {
                System.assertEquals(false, wrapper.selected);
            }
            
            // test scenario when no sighting is selected, and the user hits the approve button
            controller.reset();
            
            controller.approve();
            // this should have generated an error message
            List<Apexpages.Message> msgs = ApexPages.getMessages();
            System.assert(msgs[0].getDetail().contains('You have not selected any record for approval.'));
            
            controller.reject();
            msgs = ApexPages.getMessages();
            System.assert(msgs[1].getDetail().contains('You have not selected any record for rejection.'));
            
            // reject the records on page 1 and page 2
            controller.first();
            wrappers = controller.getSightingWrappers();
            for (SightingsValidatorController.SightingWrapper wrapper : wrappers) {
                wrapper.selected = true;
            }
            
            // go to page2
            controller.next();
            wrappers = controller.getSightingWrappers();
            for (SightingsValidatorController.SightingWrapper wrapper : wrappers) {
                wrapper.selected = true;
            }
            controller.reject();
            System.assertEquals(1, controller.getPageNumber());
            
            // Check that all the records on page 1 are now rejected
            wrappers = controller.getSightingWrappers();
            for (SightingsValidatorController.SightingWrapper wrapper : wrappers) {
                System.assertEquals('Rejected', wrapper.sighting.Validation_Status__c);
            }
            
            // Check that all records on page 2 are also rejected
            controller.next();
            wrappers = controller.getSightingWrappers();
            for (SightingsValidatorController.SightingWrapper wrapper : wrappers) {
                System.assertEquals('Rejected', wrapper.sighting.Validation_Status__c);
            }
        }
    } 
    
    /** Sadly it is not possible to test the criteria based sharing via apex tests
    ** Nevertheless I will write some tests to test the OWDs
    **/
    @isTest static void testAsDifferentValidatorUsers() {
    
        List<User> fishValidatorUsers = [Select Id, 
                                        Default_Sighting_Location__Latitude__s, 
                                        Default_Sighting_Location__Longitude__s,
                                        Default_Sighting_Location__c,
                                        Username,
                                        Validation_Specialization__c 
                                    from 
                                        User 
                                    where 
                                        id in 
                                    (select userorgroupid from groupmember where group.name = 'Fish Validators')                                   
                                    and
                                        Username LIKE 'standarduser%'
                                    and
                                        Profile.Name = 'Data Validator'
                                    and
                                        Default_Sighting_Location__Latitude__s != null
                                        
                                    order by
                                        CreatedDate desc
                                    ];
                                    
        List<Sighting__c> otherSightings = new List<Sighting__c>();
        List<Sighting__c> sightings = new List<Sighting__c>();
        
        System.runAs(fishValidatorUsers[0]) {
            Species__c specie = new Species__c(Name = 'SpeciesZ', External_Id__c = 'speciesX', Species_Group__c = 'Fish');
            insert specie;
            
            // Create 5 sightings for the above species
            for (Integer x = 0; x < 5; x++) {
                Sighting__c sighting = new Sighting__c();
                sighting.Date__c = date.today().addDays(-Integer.valueOf(10 * Math.random()));
                sighting.Location_Precision__c = '10 meters';
                sighting.Location__Latitude__s = 62;
                sighting.Location__Longitude__s = -161;
                sighting.Number_of_Animals__c = x+1;
                sighting.Species__c = specie.id;
                sighting.Validation_Status__c = 'Not Validated';
                otherSightings.add(sighting);
            }
            insert otherSightings;
            
            PageReference pageRef = Page.SightingsValidator;
            Test.setCurrentPage(pageRef);
            SightingsValidatorController controller = new SightingsValidatorController();
            
            // Check that this user only has access to the sightings they created.
            System.assertEquals(otherSightings.size(), controller.recordCount);
            
            controller.first();
            List<SightingsValidatorController.SightingWrapper> wrappers = controller.getSightingWrappers();
            for (SightingsValidatorController.SightingWrapper wrapper : wrappers) {
                wrapper.selected = true;
            }
            controller.approve();
            List<ApexPages.Message> msgs = ApexPages.getMessages();
            // Check that the expected message is in pageMessages
            Boolean messageFound = false;
            for (ApexPages.Message msg : msgs) {
                if(msg.getDetail().contains('All selected records successfully approved')
                    && msg.getSeverity() == ApexPages.Severity.INFO) {
                    messageFound = true;        
                }
            }
            System.assert(messageFound);
        }
        
        // Run as another user
        System.runAs(fishValidatorUsers[1]) {                           
            List<Species__c> species = new List<Species__c>();
            for (Integer index = 0; index < 20; index++) {                      
                Species__c specie = new Species__c(Name = 'Species'+index, External_Id__c = index+'species', Species_Group__c = 'Fish');
                species.add(specie);
            }     
            database.insert(species);
                    
            // Create 100 sightings
            for (Integer index = 0; index < 100; index++) {
                Sighting__c sighting = new Sighting__c();
                sighting.Date__c = date.today().addDays(-Integer.valueOf(10 * Math.random()));
                sighting.Location_Precision__c = '10 meters';
                sighting.Location__Latitude__s = 62;
                sighting.Location__Longitude__s = -161;                               
                sighting.Number_of_Animals__c = index + 5;
                sighting.Species__c = species[math.mod(index, 20)].id;
                sighting.Validation_Status__c = 'Not Validated';
                sightings.add(sighting);
            }
            insert sightings;
            
            PageReference pageRef = Page.SightingsValidator;
            Test.setCurrentPage(pageRef);
            SightingsValidatorController controller = new SightingsValidatorController();
            
            // Check that this user too only has access to the records he owns
            // and has no access to the records created earlier by the first user
            System.assertEquals(sightings.size(), controller.recordCount);
        }
    }
    
    @isTest static void testBadUserInputs() {
    
        List<User> fishValidatorUsers = [Select Id, 
                                        Default_Sighting_Location__Latitude__s, 
                                        Default_Sighting_Location__Longitude__s,
                                        Default_Sighting_Location__c,
                                        Username,
                                        Validation_Specialization__c 
                                    from 
                                        User 
                                    where 
                                        id in 
                                    (select userorgroupid from groupmember where group.name = 'Fish Validators')                                   
                                    and
                                        Username LIKE 'standarduser%'
                                    and
                                        Profile.Name = 'Data Validator'
                                    and
                                        Default_Sighting_Location__Latitude__s != null
                                        
                                    order by
                                        CreatedDate desc
                                    ];
                                    
        List<Sighting__c> sightings = new List<Sighting__c>();
        
        System.runAs(fishValidatorUsers[0]) {
            Species__c specie = new Species__c(Name = 'Maddox', External_Id__c = 'Maddox', Species_Group__c = 'Fish');
            insert specie;
            // Create some sightings
            for (Integer index = 0; index < 10; index++) {
                Sighting__c sighting = new Sighting__c();
                sighting.Date__c = date.today().addDays(-Integer.valueOf(10 * Math.random()));
                sighting.Location_Precision__c = '10 meters';
                sighting.Location__Latitude__s = 62;
                sighting.Location__Longitude__s = -161;
                sighting.Number_of_Animals__c = index;
                sighting.Species__c = specie.id;
                sighting.Validation_Status__c = 'Not Validated';
                sightings.add(sighting);
            }
            insert sightings;
            
            PageReference pageRef = Page.SightingsValidator;
            Test.setCurrentPage(pageRef);
            SightingsValidatorController controller = new SightingsValidatorController();
            
            // Set out of range GPS coordinates. Valid latitude = -90 - 90. Valid longitude = -180 -  180
            controller.latitude = 100;
            controller.longitude = 200;
            controller.search();
            
            List<ApexPages.Message> msgs = ApexPages.getMessages();
            
            // Check that the expected error message is in pageMessages
            Boolean messageFound = false;
            for (ApexPages.Message msg : msgs) {
                if(msg.getDetail().contains('Invalid latitude, longitude in geolocation')
                    && msg.getSeverity() == ApexPages.Severity.ERROR) {
                    messageFound = true;        
                }
            }
            System.assert(messageFound);
        }
    }
    
    /** The idea is to trigger the validation rule by approving records
    ** including at least 1 record with a missing number of animals
    **/
    @isTest static void testTriggerValidationRule() {
    
        List<User> fishValidatorUsers = [Select Id, 
                                        Default_Sighting_Location__Latitude__s, 
                                        Default_Sighting_Location__Longitude__s,
                                        Default_Sighting_Location__c,
                                        Username,
                                        Validation_Specialization__c 
                                    from 
                                        User 
                                    where 
                                        id in 
                                    (select userorgroupid from groupmember where group.name = 'Fish Validators')                                   
                                    and
                                        Username LIKE 'standarduser%'
                                    and
                                        Profile.Name = 'Data Validator'
                                    and
                                        Default_Sighting_Location__Latitude__s != null
                                        
                                    order by
                                        CreatedDate desc
                                    ];
                                    
        System.runAs(fishValidatorUsers[0]) {                           
            List<Species__c> species = new List<Species__c>();
            for (Integer index = 0; index < 5; index++) {                      
                Species__c specie = new Species__c(Name = 'Species'+index, External_Id__c = index+'species', Species_Group__c = 'Fish');
                species.add(specie);
            }     
            database.insert(species);
                    
            // Create 5 sightings
            List<Sighting__c> sightings = new List<Sighting__c>();
            for (Integer index = 0; index < 5; index++) {
                Sighting__c sighting = new Sighting__c();
                sighting.Date__c = date.today().addDays(-(index + 1));
                sighting.Location_Precision__c = '10 meters';
                sighting.Location__Latitude__s = 62;
                sighting.Location__Longitude__s = -161;
                
                // Ensure that some record per page have a null Number of Animals
                if (math.mod(index, 4) != 0) {
                    sighting.Number_of_Animals__c = index + 5;
                }
                sighting.Species__c = species[index].id;
                sighting.Validation_Status__c = 'Not Validated';
                sightings.add(sighting);
            }
            insert sightings;
            
            PageReference pageRef = Page.SightingsValidator;
            Test.setCurrentPage(pageRef);
            SightingsValidatorController controller = new SightingsValidatorController();
            System.assertEquals(sightings.size(), controller.recordCount);
            
            controller.first();
            List<SightingsValidatorController.SightingWrapper> wrappers = controller.getSightingWrappers();
            
            // Check that the page size is 5
            System.assertEquals(5, wrappers.size());
            for (Integer index = 0; index < wrappers.size(); index++) {
                wrappers[index].selected = true;
                if (math.mod(index, 4) == 0) {
                    System.assertEquals(null, wrappers[index].sighting.Number_Of_Animals__c);
                }
                else {
                    System.assertNotEquals(null, wrappers[index].sighting.Number_Of_Animals__c);
                }
            }
            controller.approve();
            List<ApexPages.Message> msgs = ApexPages.getMessages();
            
            // Check that the expected error message is in pageMessages
            Boolean messageFound = false;
            for (ApexPages.Message msg : msgs) {System.debug('detailz ='+msg.getDetail());
                if(msg.getDetail().contains('Number of Animals is required to approve a sighting')
                    && msg.getSeverity() == ApexPages.Severity.ERROR) {
                    messageFound = true;        
                }
            }
            System.assert(messageFound);
            
            // test that successful records removed, page size is nolonger 5
            System.assertNotEquals(5, controller.getSightingWrappers().size());
        }
    } 
    /** since we cannot test criteria based sharing rules
    ** I intend to manually share records in Apex
    ** and then test that sharing **/
    @isTest static void testSharingRules() {
    
        // Look up 2 users
        List<User> fishValidatorUsers = [Select Id, 
                                        Default_Sighting_Location__Latitude__s, 
                                        Default_Sighting_Location__Longitude__s,
                                        Default_Sighting_Location__c,
                                        Username,
                                        Validation_Specialization__c 
                                    from 
                                        User 
                                    where 
                                        id in 
                                    (select userorgroupid from groupmember where group.name = 'Fish Validators')                                   
                                    and
                                        Username LIKE 'standarduser%'
                                    and
                                        Profile.Name = 'Data Validator'
                                    and
                                        Default_Sighting_Location__Latitude__s != null
                                        
                                    order by
                                        CreatedDate desc
                                    ];
        
        // 2 lists, each to contain sightings for a different user                          
        List<Sighting__c> sightings1 = new List<Sighting__c>();
        List<Sighting__c> sightings2 = new List<Sighting__c>();
        
        // Create the species and sightings for the first user
        System.runAs(fishValidatorUsers[0]) {
        
            Species__c specie = new Species__c(Name = 'SpeciesA', External_Id__c = 'SpeciesA', Species_Group__c = 'Birds');
            insert specie;
            
            for (Integer index = 1; index <= 5; index++) {
                Sighting__c sighting = new Sighting__c();
                sighting.Date__c = date.today().addMonths(-index); // This ensures that once we assign these records to user2, they will show up on page 1
                sighting.Location_Precision__c = '10 meters';
                sighting.Location__Latitude__s = 62;
                sighting.Location__Longitude__s = -161;
                sighting.Number_of_Animals__c = index;
                sighting.Species__c = specie.id;
                sighting.Validation_Status__c = 'Not Validated';
                sightings1.add(sighting);
            }
            insert sightings1;
        }
        
        // Create the species and sightings for the second user
        System.runAs(fishValidatorUsers[1]) {
            Species__c specie = new Species__c(Name = 'SpeciesA', External_Id__c = 'SpeciesA', Species_Group__c = 'Fish');
            insert specie;
            
            for (Integer index = 0; index < 5; index++) {
                Sighting__c sighting = new Sighting__c();
                sighting.Date__c = date.today().addDays(-Integer.valueOf(10 * Math.random()));
                sighting.Location_Precision__c = '10 meters';
                sighting.Location__Latitude__s = 62;
                sighting.Location__Longitude__s = -161;
                sighting.Number_of_Animals__c = index;
                sighting.Species__c = specie.id;
                sighting.Validation_Status__c = 'Not Validated';
                sightings2.add(sighting);
            }
            insert sightings2;
            PageReference pageRef = Page.SightingsValidator;
            Test.setCurrentPage(pageRef);
            SightingsValidatorController controller = new SightingsValidatorController();
            
            // Assert that we only have access to the sightings this user created
            System.assertEquals(sightings2.size(), controller.recordCount);
        }
        
        // As user 1, share own sightings with user 2, with read access
        System.runAs(fishValidatorUsers[0]) {
            List<Sighting__Share> sightingShares = new List<Sighting__Share>();
            for (Sighting__c sighting : sightings1) {
                Sighting__Share sightingShare = new Sighting__Share(ParentId = sighting.Id, 
                                                                        UserOrGroupId = fishValidatorUsers[1].Id,
                                                                        AccessLevel = 'Read');
                sightingShares.add(sightingShare);
            }
            insert sightingShares;
        }
        
        // User 2 checks to see that he now has access to more records
        // after user 1 shared their records
        System.runAs(fishValidatorUsers[1]) {
            PageReference pageRef = Page.SightingsValidator;
            Test.setCurrentPage(pageRef);
            SightingsValidatorController controller = new SightingsValidatorController();
            
            // Assert that we now have access to the other user's sightings
            System.assertEquals(sightings2.size() + sightings1.size(), controller.recordCount);
            
            controller.first();
            List<SightingsValidatorController.SightingWrapper> wrappers = controller.getSightingWrappers();
            for (SightingsValidatorController.SightingWrapper wrapper : wrappers) {
                wrapper.selected = true;
            }
            controller.approve();
            Boolean messageFound = false;
            List<ApexPages.Message> msgs = ApexPages.getMessages();
            for (ApexPages.Message msg : msgs) {System.debug('nuMsg ='+msg.getDetail());
                if(msg.getDetail().contains('You do not have rights to edit records that')
                    && msg.getSeverity() == ApexPages.Severity.ERROR) {
                    messageFound = true;        
                }
            }
            System.assert(messageFound);
        }
    }
}