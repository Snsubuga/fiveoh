global class BatchUserValidationsCount implements Database.Batchable<AggregateResult> {

    private String query;
    private String validationStatus = 'Approved';
    
    global BatchUserValidationsCount() {
        
        query = 'Select Validated_By__c, Count(Id) FROM Sighting__c  where Validation_Status__c = :validationStatus'+
            ' group by Validated_By__c';
    }
    
    global Iterable<AggregateResult> start(Database.BatchableContext bc) {
        return new AggregateResultIterable(query, validationStatus);
    }
    
    global void execute(Database.BatchableContext bc, List<sObject> scope) {
        List<String> userIds = new List<String>();
        Map<String, Integer> userValidations = new Map<String, Integer>();
        for(sObject sObj : scope) {
            AggregateResult ar = (AggregateResult)sObj;
            userIds.add(String.valueOf(ar.get('Validated_By__c')));
            userValidations.put(String.valueOf(ar.get('Validated_By__c')), Integer.valueOf(ar.get('expr0')));
        }

        // Get the user object and then update its Sightings_Validated__c
        Map<Id, User> usersMap = new Map<Id, User>([SELECT Id, Sightings_Validated__c from User where Id IN:userIds]);
        for (String userId : userValidations.keyset()) {
            usersMap.get(userId).Sightings_Validated__c = userValidations.get(userId);
        }
        update usersMap.values();
    }

    global void finish(Database.BatchableContext bc) { 
    }
}