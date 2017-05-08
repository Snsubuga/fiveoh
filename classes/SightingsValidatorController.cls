public with sharing class SightingsValidatorController {

    //keeps track of the offset
    private integer counter = 0;  
    
    //sets the page size
    private integer pageSize = 5;   
            
    // Map to keep track of selected sightings
    Map<String, SightingWrapper> selectedSightings = new Map<String, SightingWrapper>();
    
    // local list to keep track of records on current page
    private List<SightingWrapper> sightingWrappers;
    
    // List to be used in case of partial saves that include errors, to track the successfully saved records
    List<SightingWrapper> recordsToRemove = new List<SightingWrapper>(); 

    // The currently logged in User, used to preload the first GPS coordinates
    public User myInfo {
        get {
            return [Select Username, 
                            Default_Sighting_Location__Latitude__s, 
                            Default_Sighting_Location__Longitude__s 
                    From 
                        User 
                    Where 
                        Id = :UserInfo.getUserId()];
        }
        set;
    }
  
    public Double latitude {
        get {
            if (latitude == null) {
                latitude = myInfo.Default_Sighting_Location__Latitude__s;
            }
            return latitude;
        }
        set;
    }
    
    public Double longitude {
        get {
            if (longitude == null) {
                longitude = myInfo.Default_Sighting_Location__Longitude__s;
            }
            return longitude;
        }
        set;
    }
        
    public Integer distance {
        get {
            if (distance == null) {
                distance = 150;
            }
            return distance;
        }
        set;  
    }
    
    //used to show user the total number of records
    public integer recordCount { 
        get; set;
    }
 
    public SightingsValidatorController() {
        recordCount = [select count() from Sighting__c where DISTANCE(Location__c, GEOLOCATION(:latitude, :longitude), 'km') < :distance];
    }
    
    // Used to keep track of selected records on each page
    private void updateSightSelections() {
        if (sightingWrappers != null) { 
            for (SightingWrapper sightingWrapper : sightingWrappers) {
                if (sightingWrapper.selected) {
                    selectedSightings.put(sightingWrapper.sighting.Id, sightingWrapper);
                }
            }
        }
    }
    
    public List<SightingWrapper> getSightingWrappers() {
        try {
            Sighting__c[] sightings = [SELECT Date__c,
                                             Name,
                                             Species__r.Name,
                                             Species__r.Rarity__c,
                                             Species_Group__c,
                                             Owner.Id,
                                             Owner.Name,
                                             Location__c,
                                             Location__Latitude__s,
                                             Location__Longitude__s,
                                             Number_of_Animals__c,
                                             Validation_Status__c
                                      FROM 
                                          Sighting__c
                                      WHERE
                                          DISTANCE(Location__c, GEOLOCATION(:latitude, :longitude), 'km') < :distance 
                                      ORDER BY 
                                          Date__c, Species__r.Name ASC 
                                      LIMIT:pageSize 
                                      OFFSET:counter];
                
            updateSightSelections(); // ensure that we have an updated list of previously selected records
            sightingWrappers = new List<SightingWrapper>();
            for (Sighting__c sighting : sightings) {
                if (selectedSightings.keyset().contains(sighting.Id)) {
                    sightingWrappers.add(new SightingWrapper(sighting, true));
                }
                else {
                    sightingWrappers.add(new SightingWrapper(sighting, false));
                }
            }
            
            // handle cases where some records are not meant to be shown to
            // the user, for example in a partial saves successfully saved
            // records are not meant to be shown
            if (!recordsToRemove.isEmpty()) {
                Set<SightingWrapper> wrapperSet = new Set<SightingWrapper>(sightingWrappers);
                sightingWrappers = removeSuccessfulRecords(wrapperSet, sightingWrappers);
            }
            return sightingWrappers;
        }
        catch(QueryException e) {
            //ApexPages.addMessages(e);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));   
            return null;
        }
    }
    
    /** removes successful records from the wrapper list
    **  also ensures that the list order is maintained
    **/
    private List<SightingWrapper> removeSuccessfulRecords(Set<SightingWrapper> wrapperSet, List<SightingWrapper> wrapperList) {
        wrapperSet.removeAll(recordsToRemove);
        List<SightingWrapper> wrappers = new List<SightingWrapper>();
        for (SightingWrapper wrapper : wrapperList) {
            if (wrapperSet.contains(wrapper)) {
                wrappers.add(wrapper);
            }
        }
        return wrappers;
    }  
    public void search() {
        try {recordCount = 0;
            recordCount = [select count() from Sighting__c where DISTANCE(Location__c, GEOLOCATION(:latitude, :longitude), 'km') < :distance];
            getSightingWrappers();
            counter = 0;
        }
        catch(Exception ex) {
            ApexPages.Message m = new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage());
            ApexPages.addMessage(m);
        }
    }
    
    public void reject() {
        save(false);
    }

    public void approve() {
        save(true);
    }
    
    public void save(boolean approval) {
        recordsToRemove.clear();
        updateSightSelections();
        if (selectedSightings.isEmpty()) {
            ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 
                                'You have not selected any record for '+ (approval? 'approval.': 'rejection.') + 
                                ' Please choose at least 1 record before you click the Approve or Reject buttons');
            ApexPages.addMessage(errorMsg);
        }
        else {
            Integer uneditableRecordCount = 0;
            List<Sighting__c> dirtyRecords = new List<Sighting__c>();
            
            for (SightingWrapper wrapper : selectedSightings.values()) {
                if (wrapper.selected) {
                    Sighting__c sighting = wrapper.sighting;
                    if (approval) {
                        sighting.Validation_Status__c = 'Approved';
                    }
                    else {
                        sighting.Validation_Status__c = 'Rejected';
                    }
                    dirtyRecords.add(sighting);
                }
            }
            Database.SaveResult[] saveResults = Database.update(dirtyRecords, false);
            
            // List to track Ids of successfully saved records, will be used in case of at least 1 failed save
            List<String> successfulSaveIds = new List<String>();
            
            // Variable to track whether there was at least 1 failed save
            Boolean totalSuccess = true;
            Boolean insufficientRightsTriggered = false;
            Boolean validationRuleTriggered = false;
            
            for (Database.SaveResult saveResult : saveResults) {
                if (!saveResult.isSuccess()) {
                    totalSuccess = false;
                    for(Database.Error err : saveResult.getErrors()) {                       
                        if (err.getMessage().contains('insufficient access rights')) {
                            insufficientRightsTriggered = true;                            
                        }
                        else if(err.getMessage().contains('Number of Animals must be greater than 0')) {
                            validationRuleTriggered = true;                            
                        }
                        /**else {
                            ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 
                                err.getMessage());
                            ApexPages.addMessage(errorMsg);                            
                        }**/
                    }
                }
                else {
                    successfulSaveIds.add(saveResult.getId());
                }
            }
            if (insufficientRightsTriggered) {
                ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 
                                'You do not have rights to edit records that do not tally with your specialty');
                ApexPages.addMessage(errorMsg);
            }
            if (validationRuleTriggered) {
                ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 
                                'Some of the records did not save. Number of Animals is required to approve a sighting. Please try again');
                ApexPages.addMessage(errorMsg);
            }
            
            if (!totalSuccess) {
    
                // Need to track the successfully updated records for removal from page
                if (!successfulSaveIds.isEmpty()) {
                    Set<SightingWrapper> wrapperSet = new Set<SightingWrapper>(sightingWrappers);
                    for (SightingWrapper wrapper : wrapperSet) {
                        for (String successfulSaveId : successfulSaveIds) { 
                            if (wrapper.sighting.Id == successfulSaveId) {
                                recordsToRemove.add(wrapper);
                                break;
                            }
                        }
                    }
                }
            }
            else {
                if (approval) {
                    ApexPages.Message successMsg = new ApexPages.Message(ApexPages.Severity.INFO, 'All selected records successfully approved');
                    ApexPages.addMessage(successMsg);
                }
                else {
                    ApexPages.Message successMsg = new ApexPages.Message(ApexPages.Severity.INFO, 'All selected records successfully rejected');
                    ApexPages.addMessage(successMsg);
                }
            }
            reset();
        }
    }
    
    // clear all the checkbox selections
    public void reset() {
        for (SightingWrapper wrapper : sightingWrappers) {
            wrapper.selected = false;
        }
        selectedSightings.clear();
        counter = 0;
    }

    // go to the first page
    public void first() {
        counter = 0;
    }
    
    // go to the previous page
    public void previous() {
        counter -= pageSize;
    }
    
    // go to the next page
    public void next() {
        counter += pageSize;
    }
    
    // go to the last page
    public void last() {
        if(math.mod(recordCount, pageSize) == 0) {
            counter = ((recordCount/pageSize) - 1) * pageSize;
        }
        else if(math.mod(recordCount, pageSize) != 0) {
            counter = (recordCount/pageSize) * pageSize;
        }
    }

    // used to disable first and previous buttons
    public Boolean getDisablePrevious() {
        if (counter > 0) { 
            return false; 
        }
        else {
            return true;
        }
    }

    // used to disable next and last buttons
    public Boolean getDisableNext() {
        if (counter + pageSize < recordCount) {
            return false; 
        }
        else {
            return true;
        }
    }
    
    // get the current page   
    public Integer getPageNumber() {
        return counter/pageSize + 1;
    }
    
    // get total number of pages
    public Integer getTotalPages() {
        if (math.mod(recordCount, pageSize) > 0 || recordCount == 0) {
            return recordCount/pageSize + 1;
        } 
        else {
            return (recordCount/pageSize);
        }
    }

    // Wrapper class to be used to set up checkboxes
    public class SightingWrapper {
    
        public Boolean selected {get; set;}
        public Sighting__c sighting {get; set;}
        
        public SightingWrapper(Sighting__c sighting, Boolean selected) {
            this.selected = selected;
            this.sighting = sighting;
        }
        
        // This object will be used in a set, hence the need to override equals and hashcode
        public Boolean equals(Object obj) {
            SightingWrapper objWrapper = (SightingWrapper)obj;
            return (objWrapper.sighting.Id == this.sighting.Id);
        }
        
        /** generic implementation because matching the wrapper's sighting Id is
        ** sufficient to prove equality **/
        public Integer hashCode() {
            return 5;
        }
    }
}